# Notion Database Setup for Stock Analysis

Run this in a new QuantWise session where Notion MCP is connected.

## Create Database

Use `mcp__notion__notion-create-database` to create:

**Database: Stock Analysis**

Properties:
| Property | Type | Description |
|----------|------|-------------|
| Symbol | Title | 股票代码 (e.g., AAPL) |
| Price | Number | 当前价格 |
| Change % | Number | 涨跌幅 |
| Market Cap | Number | 市值 |
| PE Ratio | Number | 市盈率 |
| Volume | Number | 成交量 |
| Analysis Type | Select | technical / fundamental / screener |
| Recommendation | Select | buy / sell / hold |
| Summary | Rich Text | 分析摘要 |
| Fetched At | Date | 数据获取时间 |

## Quick Command

In a new session, say:
```
Create a Notion database called "Stock Analysis" with these properties:
Symbol (title), Price (number), Change % (number), Market Cap (number),
PE Ratio (number), Volume (number), Analysis Type (select: technical/fundamental/screener),
Recommendation (select: buy/sell/hold), Summary (rich text), Fetched At (date)
```
