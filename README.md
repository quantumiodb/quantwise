# QuantWise

An agentic coding & trading intelligence tool that lives in your terminal. Built on Claude, it understands your codebase and provides market analysis — all through natural language commands.

## Install

```bash
npm install -g quantwise
```

Or use the install script (standalone binary):

```bash
curl -fsSL https://raw.githubusercontent.com/quantumiodb/ccode/main/install.sh | bash
```

## Setup

```bash
export ANTHROPIC_API_KEY=sk-ant-...
quantwise
```

## Quick Start

```bash
# Start interactive session
quantwise

# One-shot command
quantwise -p "explain this project's architecture"

# Pipe input
git diff | quantwise -p "review this diff"
```

## Features

### Coding Assistant
- Edit files, fix bugs, refactor code across your codebase
- Answer questions about code architecture and logic
- Execute and fix tests, lint, and other commands
- Git operations: merge conflicts, commits, PRs

### Trading & Market Intelligence (30+ built-in skills)
- **Stock Analysis** — real-time quotes, technical analysis, candlestick charts
- **Market Environment** — global market analysis (US, Europe, Asia, FX, Commodities)
- **Market Top/Bottom Detection** — O'Neil distribution days, Follow-Through Day signals
- **CANSLIM Screener** — William O'Neil growth stock methodology
- **VCP Screener** — Minervini Volatility Contraction Patterns
- **Options Strategy** — Black-Scholes pricing, Greeks, P/L simulation
- **Institutional Flow** — 13F filings tracking for smart money signals
- **Portfolio Manager** — holdings analysis, risk metrics, rebalancing
- **Weekly Strategy** — automated trading strategy report generation

### Built-in Tools
- **Bash** — execute shell commands
- **File operations** — read, write, edit, glob, grep
- **Web** — fetch URLs, search the web
- **Browser** — headless browser control (navigate, click, screenshot)
- **Debugger** — interactive LLDB/GDB debugging
- **Psql** — interactive PostgreSQL sessions
- **Notebook** — read and edit Jupyter notebooks

### Integrations (via MCP)
- Notion, Xiaohongshu, stock data, and more

## Skills

QuantWise ships with 30+ trading & analysis skills. Use them as slash commands:

```
/stock AAPL
/chart TSLA
/canslim-screener
/market-top-detector
/weekly-trade-strategy
```

List all available skills: type `/` in the interactive session.

## Install Skills from Marketplace

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

## Apps

### [macOS App](./apps/macos/)

Native macOS menubar app (Swift/SwiftUI) — chat interface, speech-to-text, TTS, camera integration, permission management.

```bash
cd apps/macos && swift build
```

## Assets

### [Chrome Extension](./assets/chrome-extension/)

Browser extension for quick access to QuantWise from any webpage.

## Requirements

- [Claude Code](https://claude.ai/code) or compatible CLI
- [FMP API key](https://financialmodelingprep.com/) — most screening skills
- [Tavily API key](https://tavily.com/) — news and web search

## License

MIT
