#!/usr/bin/env python3
"""
Market Top Detector - Main Orchestrator

Integrates O'Neil (Distribution Days), Minervini (Leading Stock Deterioration),
and Monty (Defensive Sector Rotation) approaches to detect market top probability.

Usage:
    # With FMP API (recommended):
    python3 market_top_detector.py --api-key YOUR_KEY \\
        --breadth-200dma 62.26 --breadth-50dma 55.0 \\
        --put-call 0.67 --vix-term contango

    # Using environment variable:
    export FMP_API_KEY=YOUR_KEY
    python3 market_top_detector.py --breadth-200dma 62.26

    # Minimal (VIX from API, rest from CLI):
    python3 market_top_detector.py --api-key YOUR_KEY \\
        --breadth-200dma 62.26 --put-call 0.67

Output:
    - JSON: market_top_YYYY-MM-DD_HHMMSS.json
    - Markdown: market_top_YYYY-MM-DD_HHMMSS.md
"""

import argparse
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from fmp_client import FMPClient
from calculators.distribution_day_calculator import calculate_distribution_days
from calculators.leading_stock_calculator import calculate_leading_stock_health, LEADING_ETFS
from calculators.defensive_rotation_calculator import (
    calculate_defensive_rotation, DEFENSIVE_ETFS, OFFENSIVE_ETFS
)
from calculators.breadth_calculator import calculate_breadth_divergence
from calculators.index_technical_calculator import calculate_index_technical
from calculators.sentiment_calculator import calculate_sentiment
from scorer import calculate_composite_score, detect_follow_through_day
from report_generator import generate_json_report, generate_markdown_report


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Market Top Detector - O'Neil/Minervini/Monty Integration"
    )

    # API key
    parser.add_argument(
        "--api-key",
        help="FMP API key (defaults to FMP_API_KEY environment variable)"
    )

    # WebSearch-sourced data (provided by Claude before script execution)
    parser.add_argument(
        "--breadth-200dma", type=float, default=None,
        help="Percent of S&P 500 stocks above 200DMA (e.g., 62.26)"
    )
    parser.add_argument(
        "--breadth-50dma", type=float, default=None,
        help="Percent of S&P 500 stocks above 50DMA (e.g., 55.0)"
    )
    parser.add_argument(
        "--put-call", type=float, default=None,
        help="CBOE equity put/call ratio (e.g., 0.67)"
    )
    parser.add_argument(
        "--vix-term", choices=["steep_contango", "contango", "flat", "backwardation"],
        default=None,
        help="VIX term structure state"
    )
    parser.add_argument(
        "--margin-debt-yoy", type=float, default=None,
        help="Margin debt year-over-year change percent (e.g., 36.0)"
    )

    # Additional context (not scored, but included in report)
    parser.add_argument(
        "--context", nargs="*", default=[],
        help="Additional context items in 'key=value' format (e.g., 'Consumer Confidence=57.3')"
    )

    # Output
    parser.add_argument(
        "--output-dir", default=".",
        help="Output directory for reports"
    )

    return parser.parse_args()


def main():
    args = parse_arguments()

    print("=" * 70)
    print("Market Top Detector")
    print("O'Neil (Distribution) + Minervini (Leadership) + Monty (Rotation)")
    print("=" * 70)
    print()

    # Initialize FMP client
    try:
        client = FMPClient(api_key=args.api_key)
        print("FMP API client initialized")
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    # ========================================================================
    # Step 1: Fetch shared data (indices, ETFs)
    # ========================================================================
    print()
    print("Step 1: Fetching Market Data")
    print("-" * 70)

    # S&P 500 data
    print("  Fetching S&P 500 data...", end=" ", flush=True)
    sp500_quote_list = client.get_quote("^GSPC")
    sp500_quote = sp500_quote_list[0] if sp500_quote_list else None
    sp500_history_data = client.get_historical_prices("^GSPC", days=260)
    sp500_history = sp500_history_data.get("historical", []) if sp500_history_data else []
    if sp500_quote and sp500_history:
        print(f"OK (${sp500_quote.get('price', 0):.2f}, {len(sp500_history)} days)")
    else:
        print("FAILED")
        print("ERROR: Cannot proceed without S&P 500 data", file=sys.stderr)
        sys.exit(1)

    # NASDAQ/QQQ data
    print("  Fetching NASDAQ (QQQ) data...", end=" ", flush=True)
    qqq_quote_list = client.get_quote("QQQ")
    qqq_quote = qqq_quote_list[0] if qqq_quote_list else None
    qqq_history_data = client.get_historical_prices("QQQ", days=260)
    qqq_history = qqq_history_data.get("historical", []) if qqq_history_data else []
    if qqq_quote and qqq_history:
        print(f"OK (${qqq_quote.get('price', 0):.2f}, {len(qqq_history)} days)")
    else:
        print("WARN - NASDAQ data unavailable, using S&P 500 only")

    # VIX
    print("  Fetching VIX...", end=" ", flush=True)
    vix_quote_list = client.get_quote("^VIX")
    vix_quote = vix_quote_list[0] if vix_quote_list else None
    vix_level = vix_quote.get("price", None) if vix_quote else None
    if vix_level:
        print(f"OK ({vix_level:.2f})")
    else:
        print("WARN - VIX unavailable")

    # Leading ETFs
    print("  Fetching Leading ETFs...", end=" ", flush=True)
    leading_quotes = client.get_batch_quotes(LEADING_ETFS)
    leading_historical = client.get_batch_historical(LEADING_ETFS, days=60)
    print(f"OK ({len(leading_quotes)} quotes, {len(leading_historical)} histories)")

    # Sector ETFs
    all_sector_etfs = list(set(DEFENSIVE_ETFS + OFFENSIVE_ETFS))
    # Remove QQQ from sector fetching if already fetched
    sector_etfs_to_fetch = [e for e in all_sector_etfs if e != "QQQ"]
    print("  Fetching Sector ETFs...", end=" ", flush=True)
    sector_historical = client.get_batch_historical(sector_etfs_to_fetch, days=30)
    # Add QQQ history if available
    if qqq_history:
        sector_historical["QQQ"] = qqq_history[:30]
    print(f"OK ({len(sector_historical)} ETFs)")

    print()

    # ========================================================================
    # Step 2: Calculate Components
    # ========================================================================
    print("Step 2: Calculating Components")
    print("-" * 70)

    # Component 1: Distribution Days (25%)
    print("  [1/6] Distribution Day Count...", end=" ", flush=True)
    comp1 = calculate_distribution_days(sp500_history, qqq_history)
    print(f"Score: {comp1['score']} ({comp1['signal']})")

    # Component 2: Leading Stock Health (20%)
    print("  [2/6] Leading Stock Health...", end=" ", flush=True)
    comp2 = calculate_leading_stock_health(leading_quotes, leading_historical)
    print(f"Score: {comp2['score']} ({comp2['signal']})")

    # Component 3: Defensive Rotation (15%)
    print("  [3/6] Defensive Sector Rotation...", end=" ", flush=True)
    comp3 = calculate_defensive_rotation(sector_historical)
    print(f"Score: {comp3['score']} ({comp3['signal']})")

    # Component 4: Breadth Divergence (15%)
    print("  [4/6] Market Breadth Divergence...", end=" ", flush=True)
    # Calculate index distance from 52-week high
    sp500_year_high = sp500_quote.get("yearHigh", 0)
    sp500_price = sp500_quote.get("price", 0)
    if sp500_year_high > 0:
        index_dist = (sp500_price - sp500_year_high) / sp500_year_high * 100
    else:
        index_dist = 0

    comp4 = calculate_breadth_divergence(
        breadth_200dma=args.breadth_200dma,
        breadth_50dma=args.breadth_50dma,
        index_distance_from_high_pct=index_dist
    )
    print(f"Score: {comp4['score']} ({comp4['signal']})")

    # Component 5: Index Technical (15%)
    print("  [5/6] Index Technical Condition...", end=" ", flush=True)
    comp5 = calculate_index_technical(
        sp500_history, qqq_history,
        sp500_quote=sp500_quote, nasdaq_quote=qqq_quote
    )
    print(f"Score: {comp5['score']} ({comp5['signal']})")

    # Component 6: Sentiment (10%)
    print("  [6/6] Sentiment & Speculation...", end=" ", flush=True)
    comp6 = calculate_sentiment(
        vix_level=vix_level,
        put_call_ratio=args.put_call,
        vix_term_structure=args.vix_term,
        margin_debt_yoy_pct=args.margin_debt_yoy
    )
    print(f"Score: {comp6['score']} ({comp6['signal']})")

    print()

    # ========================================================================
    # Step 3: Composite Score
    # ========================================================================
    print("Step 3: Calculating Composite Score")
    print("-" * 70)

    component_scores = {
        "distribution_days": comp1["score"],
        "leading_stocks": comp2["score"],
        "defensive_rotation": comp3["score"],
        "breadth_divergence": comp4["score"],
        "index_technical": comp5["score"],
        "sentiment": comp6["score"],
    }

    data_availability = {
        "distribution_days": True,  # Always available (requires S&P data to run)
        "leading_stocks": comp2.get("data_available", True),
        "defensive_rotation": comp3.get("data_available", True),
        "breadth_divergence": comp4.get("data_available", True),
        "index_technical": comp5.get("data_available", True),
        "sentiment": comp6.get("data_available", True),
    }

    composite = calculate_composite_score(component_scores, data_availability)

    print(f"  Composite Score: {composite['composite_score']}/100")
    print(f"  Risk Zone: {composite['zone']}")
    print(f"  Risk Budget: {composite['risk_budget']}")
    print(f"  Strongest Warning: {composite['strongest_warning']['label']} "
          f"({composite['strongest_warning']['score']})")
    print()

    # ========================================================================
    # Step 4: Follow-Through Day Check
    # ========================================================================
    ftd = detect_follow_through_day(sp500_history, composite['composite_score'])
    if ftd.get("applicable"):
        print("Step 4: Follow-Through Day Monitor")
        print("-" * 70)
        print(f"  {ftd['reason']}")
        print()

    # ========================================================================
    # Step 5: Generate Reports
    # ========================================================================
    print("Step 5: Generating Reports")
    print("-" * 70)

    # Parse additional context
    additional_context = {}
    for item in args.context:
        if "=" in item:
            key, value = item.split("=", 1)
            additional_context[key.strip()] = value.strip()

    # Build full analysis
    analysis = {
        "metadata": {
            "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "data_mode": "FMP API + CLI inputs",
            "api_calls": client.get_api_stats(),
            "cli_inputs": {
                "breadth_200dma": args.breadth_200dma,
                "breadth_50dma": args.breadth_50dma,
                "put_call_ratio": args.put_call,
                "vix_term_structure": args.vix_term,
                "margin_debt_yoy_pct": args.margin_debt_yoy,
            },
            "index_data": {
                "sp500_price": sp500_price,
                "sp500_year_high": sp500_year_high,
                "sp500_distance_from_high_pct": round(index_dist, 2),
                "qqq_price": qqq_quote.get("price", 0) if qqq_quote else None,
                "vix_level": vix_level,
            },
        },
        "composite": composite,
        "components": {
            "distribution_days": comp1,
            "leading_stocks": comp2,
            "defensive_rotation": comp3,
            "breadth_divergence": comp4,
            "index_technical": comp5,
            "sentiment": comp6,
        },
        "follow_through_day": ftd,
        "additional_context": additional_context,
    }

    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    json_file = os.path.join(args.output_dir, f"market_top_{timestamp}.json")
    md_file = os.path.join(args.output_dir, f"market_top_{timestamp}.md")

    generate_json_report(analysis, json_file)
    generate_markdown_report(analysis, md_file)

    print()
    print("=" * 70)
    print("Market Top Detection Complete")
    print("=" * 70)
    print(f"  Composite Score: {composite['composite_score']}/100")
    print(f"  Risk Zone: {composite['zone']}")
    print(f"  Risk Budget: {composite['risk_budget']}")
    print(f"  JSON Report: {json_file}")
    print(f"  Markdown Report: {md_file}")
    print()

    stats = client.get_api_stats()
    print(f"API Usage:")
    print(f"  API calls made: {stats['api_calls_made']}")
    print(f"  Cache entries: {stats['cache_entries']}")
    print()


if __name__ == "__main__":
    main()
