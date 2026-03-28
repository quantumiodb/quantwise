---
name: deep-research
description: 个股深度研究。串行运行基本面、技术面、催化剂、风险4个分析agent，自动整合为综合研报并存入Notion。用法：/deep-research AAPL。触发：深度分析、个股研究、comprehensive analysis、deep dive、deep research
argument-hint: "stock ticker (e.g., AAPL)"
allowed-tools: [Bash, WebSearch, WebFetch, Edit, Replace, mcp__notion__notion-create-pages, mcp__notion__notion-search, mcp__notion__notion-query-database-view]
---

# Deep Research - 个股深度研究

## Overview

对单只股票进行全维度深度分析，通过启动4个专业分析 agent，最终整合为一份综合研报。

**核心流程：**
```
/deep-research TICKER
  │
  ├─→ [fundamental-analyst] → fundamental.md   ┐
  ├─→ [technical-analyst]   → technical.md     │ 串行执行
  ├─→ [catalyst-analyst]    → catalyst.md      │ (依次完成)
  ├─→ [risk-analyst]        → risk.md          ┘
  │
  └─→ [主流程整合] → deep_research_TICKER_DATE.md → [Notion]
```

**依赖的 agent：**
- fundamental-analyst（基本面分析）
- technical-analyst（技术面分析）
- catalyst-analyst（催化剂与新闻分析）
- risk-analyst（宏观与风险分析）

**输出格式：** 中文 Markdown 综合研报 + Notion 存档

---

## When to Use This Skill

**触发关键词：**
- "深度分析 AAPL"
- "个股研究 TSLA"
- "deep research NVDA"
- "comprehensive analysis"
- "deep dive"
- "出一份研报"

**不适用场景：**
- 纯技术面分析（用 technical-analyst）
- 纯新闻分析（用 market-news-analyst）
- 大盘/市场分析（用 weekly-trade-strategy）

---

## Workflow

### Step 0: 准备工作

**解析参数：**
从 `$ARGUMENTS` 中提取 ticker symbol（转为大写）。如果未提供 ticker，提示用户输入。

**确定日期：**
使用当前日期作为 DATE（格式 YYYYMMDD）。

**创建输出目录：**
```bash
TICKER=$(echo "$ARGUMENTS" | tr '[:lower:]' '[:upper:]' | xargs)
DATE=$(date +%Y%m%d)
mkdir -p skills/deep-research/reports/${TICKER}_${DATE}
```

---

### Step 1: 串行执行4个分析 Agent

**关键：依次启动4个 Agent，等待每个完成后再启动下一个。**

使用 Agent tool 依次执行以下4个分析，每个使用 `model: sonnet`：

#### Agent 1: fundamental-analyst（先执行，等待完成）
```
Agent(
  subagent_type: "fundamental-analyst",
  prompt: "分析 {TICKER}，输出目录: skills/deep-research/reports/{TICKER}_{DATE}/"
)
```

#### Agent 2: technical-analyst（等 Agent 1 完成后执行）
```
Agent(
  subagent_type: "technical-analyst",
  prompt: "分析 {TICKER}，输出目录: skills/deep-research/reports/{TICKER}_{DATE}/"
)
```

#### Agent 3: catalyst-analyst（等 Agent 2 完成后执行）
```
Agent(
  subagent_type: "catalyst-analyst",
  prompt: "分析 {TICKER}，输出目录: skills/deep-research/reports/{TICKER}_{DATE}/"
)
```

#### Agent 4: risk-analyst（等 Agent 3 完成后执行）
```
Agent(
  subagent_type: "risk-analyst",
  prompt: "分析 {TICKER}，输出目录: skills/deep-research/reports/{TICKER}_{DATE}/"
)
```

**重要：** 每个 Agent 调用必须等待上一个返回结果后再发出，确保串行顺序执行。各 agent 的完整分析框架已定义在对应的 agent 文件中，无需在此重复。

---

### Step 2: 整合综合研报

等待4个 agent 全部完成后：

1. **读取4份子报告：**
```
Read: skills/deep-research/reports/{TICKER}_{DATE}/fundamental.md
Read: skills/deep-research/reports/{TICKER}_{DATE}/technical.md
Read: skills/deep-research/reports/{TICKER}_{DATE}/catalyst.md
Read: skills/deep-research/reports/{TICKER}_{DATE}/risk.md
```

2. **整合为最终研报**，遵循下方"综合研报结构"模板

3. **保存最终研报：**
```
Write: skills/deep-research/reports/{TICKER}_{DATE}/deep_research_{TICKER}_{DATE}.md
```

---

### Step 3: 存入 Notion

将最终综合研报存入 Notion "Stock Analysis" 数据库：

1. **搜索数据库**：用 `mcp__notion__notion-search` 搜索 "Stock Analysis" 数据库
2. **创建页面**：用 `mcp__notion__notion-create-pages` 写入，填充以下属性：

```
Symbol: {TICKER}
Analysis Type: "fundamental"（选 fundamental 代表综合分析）
Recommendation: "buy" / "sell" / "hold"（根据综合评级映射）
Summary: 投资摘要部分的3-5句话
Fetched At: 当前日期时间
```

3. **页面正文**：将完整综合研报的 Markdown 内容作为页面 body 写入

**评级映射规则：**
- 强烈看多 / 看多 → "buy"
- 中性 → "hold"
- 看空 / 强烈看空 → "sell"

**如果 Notion MCP 不可用**：跳过此步骤，仅保留本地文件，向用户说明。

---

### Step 4: 输出确认

- 显示最终研报的投资摘要部分
- 确认所有5个本地文件已保存
- 确认 Notion 页面创建状态
- 报告各 agent 的执行状态

---

## 综合研报结构

最终研报须包含以下所有章节（约 200-300 行中文）：

```markdown
# 深度研究报告: {TICKER} - {YYYY-MM-DD}

## 投资摘要
[3-5句话总结：综合评级 + 核心投资逻辑 + 关键风险 + 目标价区间]

## 1. 基本面分析

### 1.1 业务质量
[商业模式、竞争优势、护城河评估]

### 1.2 财务健康度
[营收增长、利润率趋势、现金流、负债水平]

### 1.3 估值评估
[P/E、P/S、EV/EBITDA 等估值指标 vs 历史和同业]

### 1.4 同业对比
[与主要竞争对手的关键指标对比表]

## 2. 技术面分析

### 2.1 趋势判断
[短期/中期/长期趋势方向和强度]

### 2.2 关键价位
[支撑位和阻力位，附具体价格]

### 2.3 形态与动量
[图表形态、RSI、MACD 等动量指标状态]

### 2.4 技术评级
[综合技术评分和买卖信号]

## 3. 催化剂与时间线

### 3.1 近期新闻影响
[过去30天内的重要新闻及市场反应]

### 3.2 机构持仓动向
[最新13F报告、大额增减仓信息]

### 3.3 未来事件日历
[未来60天内的财报、产品发布、行业会议等]

### 3.4 催化剂评级
[正面/负面催化剂强度评估]

## 4. 风险评估

### 4.1 宏观环境适配度
[当前宏观环境对该股票的影响]

### 4.2 行业/个股特有风险
[竞争、监管、技术替代等风险]

### 4.3 下行情景分析
[最差情景下的估值和价格预测]

## 5. 投资建议

### 5.1 综合评级
[强烈看多 / 看多 / 中性 / 看空 / 强烈看空]

### 5.2 仓位建议
[建议占组合比例，附理由]

### 5.3 入场策略
[建议入场价位和时机]

### 5.4 止损与目标价
[止损价位 / 第一目标 / 第二目标]

### 5.5 关键监控指标
[需要持续跟踪的关键指标和触发条件]

## 附录
- **数据来源**: [列出所有数据来源]
- **分析日期**: {YYYY-MM-DD}
- **免责声明**: 本报告仅供教育和信息参考，不构成投资建议。投资有风险，入市需谨慎。
```

---

## Quality Standards

**内容质量：**
- 中文输出，英文用于技术术语和数据
- 数据驱动，每个判断附带具体数据支撑
- 概率评估需合理
- 避免主观臆断，标注不确定性

**整合质量：**
- 不同维度的分析应相互交叉验证
- 如果基本面和技术面信号矛盾，须明确指出
- 投资建议须综合考虑所有4个维度

**实用性：**
- 提供具体的价位和操作建议
- 明确的止损和目标价
- 可直接用于交易决策的信息密度

---

## Troubleshooting

**问题：某个 agent 执行失败**
→ 用该 agent 的分析框架在主流程中补充分析，并在报告中注明

**问题：WebSearch 获取数据不完整**
→ 基于已有数据生成报告，标注数据缺失部分

**问题：ticker 无法识别**
→ 提示用户确认股票代码是否正确

---

## Important Notes

- 本技能为**编排型技能**，通过串行 agent 依次执行
- 4个 agent 使用 sonnet 模型，性价比最优
- 所有分析和输出使用中文
- 这是教育和信息用途，不构成投资建议

---

**Version:** 1.1
**Last Updated:** 2026-03-17
**Execution Time:** ~10-15 分钟（串行执行，4个 agent 依次完成）
**Output:** 1份综合研报 + 4份子报告 + Notion 页面
**Dependencies:** WebSearch + 4个分析 agent + Notion MCP（可选）
