---
name: stock
description: "股票分析工作站。查询实时行情、技术分析、终端K线图、存入Notion。当用户询问股票、行情、分析、交易时使用。"
user-invocable: true
allowed-tools: [Bash, mcp__stock-analysis__get_stock_quote, mcp__notion__notion-create-pages, mcp__notion__notion-search, mcp__notion__notion-query-database-view]
context: inline
argument-hint: "AAPL 或 chart AAPL / save AAPL / history AAPL / analyze AAPL"
---

## 股票分析工作站

根据用户参数执行对应操作：

### 命令路由

1. **`/stock <SYMBOL>`** — 查询实时行情
   - 调用 `mcp__stock-analysis__get_stock_quote` 获取 ticker 为 $ARGUMENTS 的数据
   - 格式化展示：价格、涨跌幅、市值、PE、成交量

2. **`/stock chart <SYMBOL>`** — 终端 K 线图
   - 获取 OHLCV 数据
   - 写入 /tmp/chart_<SYMBOL>.json，格式：[{open, high, low, close, volume, timestamp, type}]
   - 执行 Bash: `candlestick-cli -f /tmp/chart_<SYMBOL>.json -t "<SYMBOL>" --height 25`

3. **`/stock save <SYMBOL>`** — 存入 Notion
   - 获取实时数据后，用 `mcp__notion__notion-create-pages` 写入 Stock Analysis 数据库
   - 填充所有属性字段

4. **`/stock history <SYMBOL>`** — 查询历史
   - 用 `mcp__notion__notion-search` 搜索该 symbol 的历史记录
   - 表格形式展示

5. **`/stock analyze <SYMBOL>`** — 深度分析
   - 获取数据后，运用技术分析和基本面知识进行综合分析
   - 输出买卖建议和信心评级
   - 自动存入 Notion

如果参数不匹配以上命令，默认执行查询实时行情。
