---
name: market-top-detector
description: Detect market top probability (0-100 score) via distribution days, leading stock deterioration, defensive rotation. For correction timing, reducing exposure decisions.
allowed-tools: [WebSearch, WebFetch, Bash(python3:*)]
---

# Market Top Detector

6-dimension quantitative scoring (0-100) for 2-8 week tactical correction signals. Requires FMP API key (~33 calls per run).

## Step 1: WebSearch Data Collection

Collect these values before running the script:

| Search Query | CLI Flag | Example |
|---|---|---|
| "S&P 500 stocks above 200 day moving average percent" | `--breadth-200dma` | 62.26 |
| "S&P 500 stocks above 50 day moving average percent" | `--breadth-50dma` | 55.0 |
| "CBOE equity put call ratio current" | `--put-call` | 0.67 |
| "VIX term structure contango backwardation" | `--vix-term` | contango |
| (optional) "FINRA margin debt latest year over year" | `--margin-debt-yoy` | 36.0 |

## Step 2: Run Script

```bash
python3 .claude/skills/market-top-detector/scripts/market_top_detector.py \
  --api-key $FMP_API_KEY \
  --breadth-200dma [VALUE] --breadth-50dma [VALUE] \
  --put-call [VALUE] --vix-term [steep_contango|contango|flat|backwardation]
```

The script fetches index/ETF data from FMP API, calculates all 6 dimensions, and outputs JSON + Markdown reports.

## Step 3: Present Results

Show the markdown report. Highlight composite score, risk zone, strongest warning, and recommended actions.

## Reference docs (load only when deep-dive is needed)

- `references/market_top_methodology.md` — O'Neil/Minervini/Monty framework details
- `references/distribution_day_guide.md` — Distribution day counting rules
- `references/historical_tops.md` — 2000/2007/2018/2022 case studies
