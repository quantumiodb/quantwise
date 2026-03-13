# Trading Skills

29 professional trading analysis skills for US equity markets. Covers market timing, stock screening, portfolio management, macro analysis, and strategy generation.

## Installation

```
/plugin marketplace add https://github.com/quantumiodb/quantwise
/plugin install trading-skills@quantwise
```

## Skills

### Market Timing & Risk

| Skill | Description |
|-------|-------------|
| `market-top-detector` | O'Neil distribution days + Minervini leading stock deterioration + defensive rotation. Generates 0-100 risk score |
| `ftd-detector` | Follow-Through Day signals to confirm market bottoms (William O'Neil methodology) |
| `us-market-bubble-detector` | Minsky/Kindleberger framework v2.1 — quantitative bubble risk assessment |
| `market-breadth-analyzer` | TraderMonty CSV data — 6-dimension breadth health score (0-100) |
| `uptrend-analyzer` | Monty uptrend ratio dashboard — 5-dimension market environment diagnosis |
| `breadth-chart-analyst` | S&P 500 Breadth Index & Uptrend Stock Ratio chart analysis |
| `macro-regime-detector` | Cross-asset ratio analysis for 1-2 year structural regime transitions |

### Stock Screening

| Skill | Description |
|-------|-------------|
| `canslim-screener` | William O'Neil's CANSLIM growth stock methodology |
| `vcp-screener` | Mark Minervini's Volatility Contraction Pattern (S&P 500) |
| `value-dividend-screener` | Value + high dividend screening (P/E < 20, yield > 3%) |
| `dividend-growth-pullback-screener` | Dividend growth stocks at RSI oversold pullbacks |
| `pair-trade-screener` | Statistical arbitrage — cointegrated pairs with z-score signals |
| `theme-detector` | Trending market themes and sector rotation lifecycle analysis |
| `institutional-flow-tracker` | 13F filings — smart money accumulation/distribution tracking |

### Analysis & Research

| Skill | Description |
|-------|-------------|
| `stock` | Stock analysis workstation — real-time quotes, technicals, terminal charts, Notion sync |
| `chart` | Terminal candlestick K-line charts |
| `us-stock-analysis` | Comprehensive fundamental + technical analysis with investment reports |
| `technical-analyst` | Weekly chart pattern analysis from images |
| `sector-analyst` | Sector/industry performance chart analysis and rotation assessment |
| `market-environment-analysis` | Global market environment report (US, Europe, Asia, FX, commodities) |
| `market-news-analyst` | Recent market-moving news impact analysis |
| `scenario-analyzer` | 18-month scenario analysis with 1st/2nd/3rd order effects |
| `earnings-calendar` | Upcoming earnings announcements (FMP API, $2B+ market cap) |
| `economic-calendar-fetcher` | Economic events and data releases calendar |

### Strategy & Portfolio

| Skill | Description |
|-------|-------------|
| `weekly-trade-strategy` | Weekly trading strategy blog generation (4-step workflow) |
| `portfolio-manager` | Portfolio analysis via Alpaca MCP — allocation, risk, rebalancing |
| `options-strategy-advisor` | Options pricing (Black-Scholes), Greeks, P/L simulation |
| `backtest-expert` | Systematic backtesting methodology and robustness testing |
| `stanley-druckenmiller-investment` | Druckenmiller-style macro analysis and position building |

## Requirements

- [FMP API key](https://financialmodelingprep.com/) for most screening skills
- [Tavily API key](https://tavily.com/) for news and web search
- [Alpaca MCP Server](https://github.com/alpacahq) for portfolio-manager (optional)
