---
name: chart
description: "终端K线图。将股票数据渲染为终端candlestick图表。用法: /chart AAPL"
user-invocable: true
allowed-tools: [Bash, mcp__stock-analysis__get_stock_quote]
context: inline
argument-hint: "股票代码"
---

## 终端 K 线图渲染

1. 调用 `mcp__stock-analysis__get_stock_quote` 获取 $ARGUMENTS 的 OHLCV 数据
2. 将数据转换为 candlestick-cli JSON 格式：
   ```json
   [{"open": 150.0, "high": 155.0, "low": 149.0, "close": 153.0, "volume": 1000000, "timestamp": 1640995200000, "type": 1}]
   ```
   type: close >= open 则为 1（涨），否则为 0（跌）
3. 写入 /tmp/chart_$ARGUMENTS.json
4. 执行: `candlestick-cli -f /tmp/chart_$ARGUMENTS.json -t "$ARGUMENTS" --height 25`
5. 展示图表输出
