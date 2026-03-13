#!/usr/bin/env python3
"""
Component 6: S&P 500 vs Breadth Divergence (Weight: 10%)

Detects divergence between price action and breadth participation.

Input: S&P500_Price, Breadth_Index_8MA (last 60 days)

Scoring (100 = healthy):
  60-day changes:
    sp500_pct = (latest - 60d_ago) / 60d_ago * 100
    breadth_change = latest_8ma - 8ma_60d_ago

  Both rising                        -> 70 (healthy rally)
  Both falling                       -> 30 (consistent decline)
  SP up(>3%) & Breadth down(<-0.05)  -> 10 (dangerous divergence)
  SP up(>1%) & Breadth down(<-0.03)  -> 25
  SP down(<-3%) & Breadth up(>+0.05) -> 80 (bullish divergence)
  SP down(<-1%) & Breadth up(>+0.03) -> 65
  Otherwise                          -> 50
"""

from typing import Dict, List


def calculate_divergence(rows: List[Dict]) -> Dict:
    """
    Calculate S&P 500 vs breadth divergence score.

    Args:
        rows: All detail rows sorted by date ascending.

    Returns:
        Dict with score, signal, and component details.
    """
    if not rows or len(rows) < 60:
        # Use whatever data is available, minimum 20 days
        if not rows or len(rows) < 20:
            return {
                "score": 50,
                "signal": "NO DATA: Insufficient data for divergence analysis",
                "data_available": False,
            }

    lookback = min(60, len(rows))
    latest = rows[-1]
    past = rows[-lookback]

    sp_latest = latest["S&P500_Price"]
    sp_past = past["S&P500_Price"]
    ma8_latest = latest["Breadth_Index_8MA"]
    ma8_past = past["Breadth_Index_8MA"]

    if sp_past <= 0:
        return {
            "score": 50,
            "signal": "NO DATA: Invalid S&P 500 price data",
            "data_available": False,
        }

    sp500_pct = (sp_latest - sp_past) / sp_past * 100
    breadth_change = ma8_latest - ma8_past

    # Determine divergence type and score
    score, div_type = _score_divergence(sp500_pct, breadth_change)
    score = max(0, min(100, score))

    signal = _generate_signal(sp500_pct, breadth_change, div_type, score)

    return {
        "score": score,
        "signal": signal,
        "data_available": True,
        "sp500_pct_change": round(sp500_pct, 2),
        "breadth_change": round(breadth_change, 4),
        "sp500_latest": sp_latest,
        "sp500_past": sp_past,
        "ma8_latest": ma8_latest,
        "ma8_past": ma8_past,
        "lookback_days": lookback,
        "divergence_type": div_type,
        "date": latest["Date"],
    }


def _score_divergence(sp_pct: float, breadth_chg: float) -> tuple:
    """Score based on price/breadth divergence. Returns (score, type_label)."""
    sp_up = sp_pct > 0
    breadth_up = breadth_chg > 0

    # Dangerous divergence: SP up, breadth down
    if sp_pct > 3.0 and breadth_chg < -0.05:
        return 10, "Dangerous bearish divergence"
    if sp_pct > 1.0 and breadth_chg < -0.03:
        return 25, "Moderate bearish divergence"

    # Bullish divergence: SP down, breadth up
    if sp_pct < -3.0 and breadth_chg > 0.05:
        return 80, "Strong bullish divergence"
    if sp_pct < -1.0 and breadth_chg > 0.03:
        return 65, "Moderate bullish divergence"

    # Aligned movements
    if sp_up and breadth_up:
        return 70, "Healthy alignment (both rising)"
    if not sp_up and not breadth_up:
        return 30, "Consistent decline (both falling)"

    return 50, "Mixed signals"


def _generate_signal(
    sp_pct: float, breadth_chg: float, div_type: str, score: int
) -> str:
    """Generate human-readable signal."""
    return (
        f"{div_type}: S&P {sp_pct:+.1f}%, "
        f"Breadth 8MA {breadth_chg:+.3f} over 60d"
    )
