#!/usr/bin/env python3
"""
Component 3: Defensive Sector Rotation (Weight: 15%)

Compares defensive ETF performance vs offensive/growth ETF performance
over the trailing 20 trading days.

Defensive: XLU, XLP, XLV, VNQ
Offensive:  XLK, XLC, XLY, QQQ

Scoring (defensive_return - offensive_return):
  +5.0% or more -> 100 (Strong rotation into defensives)
  +3.0% or more -> 80
  +1.5% or more -> 60
  +0.5% or more -> 40
  +0.0% or more -> 20
  Negative       ->  0 (Growth leading = healthy)
"""

from typing import Dict, List

DEFENSIVE_ETFS = ["XLU", "XLP", "XLV", "VNQ"]
OFFENSIVE_ETFS = ["XLK", "XLC", "XLY", "QQQ"]


def calculate_defensive_rotation(historical: Dict[str, List[Dict]],
                                 lookback: int = 20) -> Dict:
    """
    Calculate defensive vs offensive sector rotation score.

    Args:
        historical: Dict of symbol -> list of daily OHLCV (most recent first)
        lookback: Number of trading days to measure (default 20)

    Returns:
        Dict with score (0-100), relative_performance, details
    """
    def _calc_return(symbol_hist: List[Dict], days: int) -> float:
        if not symbol_hist or len(symbol_hist) < days + 1:
            return None
        recent = symbol_hist[0].get("close", symbol_hist[0].get("adjClose", 0))
        past = symbol_hist[days].get("close", symbol_hist[days].get("adjClose", 0))
        if past == 0:
            return None
        return (recent - past) / past * 100

    # Calculate average returns for each group
    def_returns = []
    def_details = {}
    for symbol in DEFENSIVE_ETFS:
        hist = historical.get(symbol, [])
        ret = _calc_return(hist, lookback)
        if ret is not None:
            def_returns.append(ret)
            def_details[symbol] = round(ret, 2)

    off_returns = []
    off_details = {}
    for symbol in OFFENSIVE_ETFS:
        hist = historical.get(symbol, [])
        ret = _calc_return(hist, lookback)
        if ret is not None:
            off_returns.append(ret)
            off_details[symbol] = round(ret, 2)

    if not def_returns or not off_returns:
        return {
            "score": 50,
            "signal": "INSUFFICIENT DATA (neutral default)",
            "data_available": False,
            "relative_performance": 0,
            "defensive_avg_return": 0,
            "offensive_avg_return": 0,
            "defensive_details": def_details,
            "offensive_details": off_details,
            "lookback_days": lookback,
        }

    def_avg = sum(def_returns) / len(def_returns)
    off_avg = sum(off_returns) / len(off_returns)
    relative = def_avg - off_avg

    score = _score_rotation(relative)

    if score >= 80:
        signal = "CRITICAL: Strong defensive rotation"
    elif score >= 60:
        signal = "WARNING: Defensive outperformance"
    elif score >= 40:
        signal = "CAUTION: Mild defensive rotation"
    elif score >= 20:
        signal = "MIXED: Slight defensive tilt"
    else:
        signal = "HEALTHY: Growth leading"

    return {
        "score": score,
        "signal": signal,
        "data_available": True,
        "relative_performance": round(relative, 2),
        "defensive_avg_return": round(def_avg, 2),
        "offensive_avg_return": round(off_avg, 2),
        "defensive_details": def_details,
        "offensive_details": off_details,
        "lookback_days": lookback,
    }


def _score_rotation(relative: float) -> int:
    """Convert relative performance (defensive - offensive) to 0-100 score"""
    if relative >= 5.0:
        return 100
    elif relative >= 3.0:
        # Linear interpolation: 3.0 -> 80, 5.0 -> 100
        return round(80 + (relative - 3.0) / 2.0 * 20)
    elif relative >= 1.5:
        return round(60 + (relative - 1.5) / 1.5 * 20)
    elif relative >= 0.5:
        return round(40 + (relative - 0.5) / 1.0 * 20)
    elif relative >= 0.0:
        return round(20 + relative / 0.5 * 20)
    else:
        # Negative: growth leading, healthy
        # Scale from 0 to 20 as relative goes from -2.0 to 0
        if relative >= -2.0:
            return round(max(0, 20 + relative / 2.0 * 20))
        return 0
