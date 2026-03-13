#!/usr/bin/env python3
"""
Component 1: Distribution Day Count (Weight: 25%)

O'Neil's Distribution Day Rules:
- Distribution Day: Index drops >= 0.2% on higher volume than previous day
- Stalling Day: Volume increases but price gain < 0.1% (half weight)
- Days expire after 25 trading days
- Count the higher of S&P 500 or NASDAQ

Scoring:
  6+ distribution days -> 100 (Critical)
  5 days -> 90
  4 days -> 75  (O'Neil's warning threshold)
  3 days -> 55
  2 days -> 30
  1 day  -> 15
  0 days -> 0
"""

from typing import Dict, List, Optional


def calculate_distribution_days(sp500_history: List[Dict],
                                nasdaq_history: List[Dict]) -> Dict:
    """
    Calculate distribution day count for S&P 500 and NASDAQ.

    Args:
        sp500_history: List of daily OHLCV dicts (most recent first), at least 30 days
        nasdaq_history: List of daily OHLCV dicts (most recent first), at least 30 days

    Returns:
        Dict with score (0-100), distribution_days, stalling_days, details
    """
    sp500_result = _count_distribution_days(sp500_history, "S&P 500")
    nasdaq_result = _count_distribution_days(nasdaq_history, "NASDAQ")

    # Use the higher (worse) effective count
    sp500_effective = sp500_result["distribution_days"] + 0.5 * sp500_result["stalling_days"]
    nasdaq_effective = nasdaq_result["distribution_days"] + 0.5 * nasdaq_result["stalling_days"]

    if sp500_effective >= nasdaq_effective:
        primary = sp500_result
        primary_name = "S&P 500"
        secondary = nasdaq_result
        secondary_name = "NASDAQ"
    else:
        primary = nasdaq_result
        primary_name = "NASDAQ"
        secondary = sp500_result
        secondary_name = "S&P 500"

    effective_count = max(sp500_effective, nasdaq_effective)
    score = _score_distribution_days(effective_count)

    # Build signal description
    if effective_count >= 5:
        signal = "CRITICAL: Heavy distribution detected"
    elif effective_count >= 4:
        signal = "WARNING: O'Neil's threshold reached"
    elif effective_count >= 3:
        signal = "CAUTION: Moderate distribution"
    elif effective_count >= 1:
        signal = "MINOR: Some distribution present"
    else:
        signal = "CLEAR: No distribution"

    return {
        "score": score,
        "effective_count": effective_count,
        "signal": signal,
        "primary_index": primary_name,
        "sp500": {
            "distribution_days": sp500_result["distribution_days"],
            "stalling_days": sp500_result["stalling_days"],
            "effective_count": sp500_effective,
            "details": sp500_result["details"],
        },
        "nasdaq": {
            "distribution_days": nasdaq_result["distribution_days"],
            "stalling_days": nasdaq_result["stalling_days"],
            "effective_count": nasdaq_effective,
            "details": nasdaq_result["details"],
        },
    }


def _count_distribution_days(history: List[Dict], index_name: str) -> Dict:
    """Count distribution and stalling days in the last 25 trading days"""
    if not history or len(history) < 2:
        return {"distribution_days": 0, "stalling_days": 0, "details": []}

    # We need at least 26 days to check 25 days of change
    # history[0] = most recent, history[1] = day before, etc.
    window = min(25, len(history) - 1)  # 25 trading day window

    distribution_days = 0
    stalling_days = 0
    details = []

    for i in range(window):
        today = history[i]
        yesterday = history[i + 1]

        today_close = today.get("close", today.get("adjClose", 0))
        yesterday_close = yesterday.get("close", yesterday.get("adjClose", 0))
        today_volume = today.get("volume", 0)
        yesterday_volume = yesterday.get("volume", 0)

        if yesterday_close == 0 or yesterday_volume == 0:
            continue

        pct_change = (today_close - yesterday_close) / yesterday_close * 100
        volume_increase = today_volume > yesterday_volume

        date = today.get("date", f"day-{i}")

        # Distribution day: price drops >= 0.2% AND volume increases
        if pct_change <= -0.2 and volume_increase:
            distribution_days += 1
            details.append({
                "date": date,
                "type": "distribution",
                "pct_change": round(pct_change, 2),
                "volume_change": round((today_volume / yesterday_volume - 1) * 100, 1),
            })

        # Stalling day: volume increases but price gain < 0.1%
        elif volume_increase and 0 <= pct_change < 0.1:
            stalling_days += 1
            details.append({
                "date": date,
                "type": "stalling",
                "pct_change": round(pct_change, 2),
                "volume_change": round((today_volume / yesterday_volume - 1) * 100, 1),
            })

    return {
        "distribution_days": distribution_days,
        "stalling_days": stalling_days,
        "details": details,
    }


def _score_distribution_days(effective_count: float) -> int:
    """Convert effective distribution day count to 0-100 score"""
    if effective_count >= 6:
        return 100
    elif effective_count >= 5:
        return 90
    elif effective_count >= 4:
        return 75
    elif effective_count >= 3:
        return 55
    elif effective_count >= 2:
        return 30
    elif effective_count >= 1:
        return 15
    else:
        return 0
