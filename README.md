# QuantWise

AI-powered trading intelligence CLI built on Claude Code. Professional-grade market analysis, stock screening, and strategy generation — all from your terminal.

## Install Skills

Add the QuantWise marketplace to Claude Code:

```
/plugin marketplace add https://github.com/quantumiodb/quantwise
```

Then install plugins:

```
/plugin install trading-skills@quantwise
/plugin install macos-tools@quantwise
```

## Plugins

### [trading-skills](./plugins/trading-skills/)

29 professional trading analysis skills for US equity markets:

- **Market Timing** — Distribution day detection, FTD bottom confirmation, bubble risk, breadth analysis, macro regime detection
- **Stock Screening** — CANSLIM, VCP (Minervini), value-dividend, pair trading, institutional flow tracking
- **Analysis** — Real-time stock workstation, terminal K-line charts, technical/fundamental analysis, sector rotation, news impact
- **Strategy** — Weekly trade strategy generation, portfolio management, options simulation, backtesting, Druckenmiller-style macro

### [macos-tools](./plugins/macos-tools/)

macOS utilities: speech recognition (dictation), cherry-pick conflict resolver.

## Requirements

- [Claude Code](https://claude.ai/code) or compatible CLI
- [FMP API key](https://financialmodelingprep.com/) — most screening skills
- [Tavily API key](https://tavily.com/) — news and web search

## License

MIT
