---
name: weekly-trade-strategy
description: 生成美股周交易策略博客。通过4步工作流（技术分析→市场环境评估→新闻分析→博客生成），为兼职交易者创建200-300行的周策略报告。可选第5步生成Druckenmiller风格18个月中长期战略。当用户请求周交易策略、周报生成、weekly blog、周末市场分析时使用。
---

# Weekly Trade Strategy Blog Generator

## Overview

自动生成美股周交易策略博客的多步编排技能。系统按顺序执行4个分析阶段，最终整合为面向兼职交易者的实用周策略文章（200-300行）。

**核心流程：**
```
图表图片 → [技术分析] → [市场评估] → [新闻分析] → [博客生成] → 周策略博客
```

**依赖的技能：**
- technical-analyst, breadth-chart-analyst, sector-analyst
- market-environment-analysis, us-market-bubble-detector
- market-news-analyst, economic-calendar-fetcher, earnings-calendar
- stanley-druckenmiller-investment（可选，中长期策略）

**输出格式：** Markdown 博客文章

---

## When to Use This Skill

**触发关键词：**
- "生成本周交易策略"
- "创建周策略博客"
- "weekly trade strategy"
- "周末市场分析并生成博客"
- "本周交易计划"

**不适用场景：**
- 单纯的技术分析（用 technical-analyst）
- 单纯的新闻分析（用 market-news-analyst）
- 个股分析（用 us-stock-analysis）

---

## Workflow

### Step 0: 准备工作

**确定日期：** 使用当前周的周一日期作为 DATE（格式 YYYY-MM-DD）。

**检查图表图片：**

```bash
# 检查图表目录
ls skills/weekly-trade-strategy/charts/$DATE/
```

如果图表目录不存在或为空：
1. 创建目录：`mkdir -p skills/weekly-trade-strategy/charts/$DATE`
2. 提示用户放入图表图片（推荐18张周线图表）：
   - VIX、美国10年期国债收益率
   - S&P 500 Breadth Index（200日均线 + 8日均线）
   - Nasdaq 100、S&P 500、Russell 2000、Dow Jones（周线）
   - 黄金、铜、原油、天然气、铀ETF（周线）
   - Uptrend Stock Ratio（全市场）
   - 板块表现（1周、1个月）
   - 行业表现（涨幅/跌幅排名）
   - 财报日历、主要个股热力图

**创建输出目录：**
```bash
mkdir -p skills/weekly-trade-strategy/reports/$DATE
```

**检查上周博客（连续性参考）：**
```bash
ls skills/weekly-trade-strategy/blogs/
```

如果没有图表图片且用户未提供，跳过 Step 1 的图表分析部分，直接用 WebSearch 获取市场数据执行 Step 1。

---

### Step 1: Technical Market Analysis（技术分析）

**目的：** 分析图表图片和市场数据，评估市场技术面

**使用技能：** technical-analyst, breadth-chart-analyst, sector-analyst

**执行方式：**

1. **如果有图表图片**：逐一分析 `charts/$DATE/` 中的图表，运用 technical-analyst 和 breadth-chart-analyst 的方法论
2. **如果没有图表**：通过 WebSearch 和 MCP 工具获取以下数据：
   - 主要指数（SPY, QQQ, IWM, DIA）的周线技术状态
   - VIX 当前值和趋势
   - 10年期国债收益率
   - 市场广度指标

3. 使用 sector-analyst 的板块轮动框架分析板块表现

**分析内容：**
- VIX、10年期国债收益率、Breadth 指标的当前值和趋势评估
- 主要指数的技术分析（趋势、支撑/阻力、移动平均线）
- 大宗商品趋势分析（黄金、铜、原油、铀）
- 板块轮动分析（进攻型 vs 防御型板块表现对比）
- 情景概率评估（Bull / Base / Bear）

**输出：** 保存至 `skills/weekly-trade-strategy/reports/$DATE/technical-market-analysis.md`

---

### Step 2: US Market Analysis（市场环境评估）

**目的：** 综合评估市场阶段和系统性风险

**使用技能：** market-environment-analysis, us-market-bubble-detector

**输入：** Step 1 的 technical-market-analysis.md + 实时市场数据

**执行方式：**

1. 读取 Step 1 的技术分析报告
2. 运用 market-environment-analysis 框架评估：
   - 当前市场阶段（Risk-On / Base / Caution / Stress）
   - 风险偏好 vs 风险规避指标
3. 运用 us-market-bubble-detector 框架评估：
   - 泡沫风险评分
   - 各维度指标（估值、情绪、杠杆、广度等）

**分析内容：**
- 当前市场阶段判定及依据
- 泡沫风险评分（Minsky/Kindleberger 框架）
- 板块轮动模式（周期性 vs 防御性）
- 波动率状态和趋势
- 关键风险因素和催化剂

**输出：** 保存至 `skills/weekly-trade-strategy/reports/$DATE/us-market-analysis.md`

---

### Step 3: Market News Analysis（新闻与事件分析）

**目的：** 分析近期新闻影响和未来事件预测

**使用技能：** market-news-analyst, economic-calendar-fetcher, earnings-calendar

**输入：** Step 1 + Step 2 的报告 + 实时新闻数据

**执行方式：**

1. 使用 market-news-analyst 分析过去10天的市场重要新闻
2. 使用 economic-calendar-fetcher 获取未来7天的经济事件日历
3. 使用 earnings-calendar 获取未来7天的重要财报日程

**分析内容：**
- 过去10天的主要新闻及其对市场的影响评级
- 未来7天的经济指标发布日程（FOMC、就业、CPI等）
- 主要财报发布（市值$2B以上的公司）
- 按事件的情景分析（附概率）
- 风险事件优先级排序

**输出：** 保存至 `skills/weekly-trade-strategy/reports/$DATE/market-news-analysis.md`

---

### Step 4: Weekly Blog Generation（博客生成）

**目的：** 整合3份报告，生成面向兼职交易者的周策略博客

**输入：**
- `reports/$DATE/technical-market-analysis.md`
- `reports/$DATE/us-market-analysis.md`
- `reports/$DATE/market-news-analysis.md`
- `blogs/` 目录中上周的博客文章（用于连续性检查）

**博客文章结构（200-300行）：**

```markdown
# Weekly Trading Strategy - [DATE]

## 📌 3句话总结
- [市场环境一句话]
- [本周焦点一句话]
- [策略方向一句话]

## 📋 本周操作
### 仓位管理
[总体仓位建议：股票 X%、现金 X%]

### 板块配置
| 板块 | 本周配置 | 上周配置 | 变动 | 理由 |
|------|---------|---------|------|------|

### 关键价位
[主要指数支撑/阻力位]

### 重要事件
[本周必须关注的事件和时间]

## 🎯 情景计划
### Base Case (XX%)
[最可能的情景和对应操作]

### Risk-On Case (XX%)
[乐观情景和对应操作]

### Caution Case (XX%)
[风险情景和对应操作]

## 📊 市场状况
### 触发指标
| 指标 | 当前值 | 警戒线 | 状态 |
|------|--------|--------|------|
| 10Y 收益率 | | | |
| VIX | | | |
| Breadth Index | | | |

## 🏭 商品与板块策略
[黄金、铜、原油、铀的策略建议]

## ⏰ 兼职交易指南
### 早间检查（开盘前5分钟）
- [ ] [检查项1]
- [ ] [检查项2]

### 晚间检查（收盘后5分钟）
- [ ] [检查项1]
- [ ] [检查项2]

## ⚠️ 风险管理
[本周特有风险和应对措施]

## 📝 总结
[3-5句话总结本周策略]

---
*Generated on [DATE] | Data sources: FMP API, WebSearch*
```

**关键约束：**
- 与上周的板块配置变动 **控制在 ±10-15% 以内**（渐进式调整）
- 在历史新高+Base触发条件下，避免大幅削减仓位
- 现金配置应渐进增加（例：10% → 20-25% → 30-35%）
- 文章长度严格控制在 200-300 行

**输出：** 保存至 `skills/weekly-trade-strategy/blogs/$DATE-weekly-strategy.md`

---

### Step 5（可选）: Druckenmiller Strategy Planning

**触发条件：** 用户明确要求，或每季度执行一次

**目的：** 制定18个月中长期投资战略

**使用技能：** stanley-druckenmiller-investment

**输入：** Step 1-3 的3份报告

**输出结构：**
```markdown
# Strategic Investment Outlook - [DATE]

## Executive Summary
## Market Context & Current Environment
## 18-Month Scenario Analysis
### Base Case (XX%)
### Bull Case (XX%)
### Bear Case (XX%)
### Tail Risk (XX%)
## Recommended Strategic Actions
### High Conviction Trades
### Medium Conviction Positions
### Hedges & Protective Strategies
## Key Monitoring Indicators
## Conclusion & Next Review Date
```

**输出：** 保存至 `skills/weekly-trade-strategy/reports/$DATE/druckenmiller-strategy.md`

---

## Data Flow

```
charts/$DATE/*.jpeg (用户提供)
  │
  ├─→ [Step 1: 技术分析] ──→ technical-market-analysis.md
  │     skills: technical-analyst, breadth-chart-analyst, sector-analyst
  │                                    │
  │                                    ├─→ [Step 2: 市场评估] ──→ us-market-analysis.md
  │                                    │     skills: market-environment-analysis, bubble-detector
  │                                    │                              │
  │                                    │                              ├─→ [Step 3: 新闻分析] ──→ market-news-analysis.md
  │                                    │                              │     skills: market-news-analyst, calendars
  │                                    │                              │
  └────────────────────────────────────┴──────────────────────────────┴─→ [Step 4: 博客生成]
                                                                              │
                                                                              └─→ blogs/$DATE-weekly-strategy.md
  上周博客 (blogs/) ──────────────────────────────────────────────────────────────┘ (连续性参考)
```

---

## Quality Standards

**内容质量：**
- 所有分析和输出使用英文
- 数据驱动，避免主观臆断
- 每个判断附带具体数据支撑
- 概率评估需合理且总和约100%

**连续性：**
- 板块配置变动 ≤ ±15%（除非出现重大事件）
- 引用上周策略执行情况
- 标注策略变更的具体原因

**实用性：**
- 面向每周投入5-10小时的兼职交易者
- 提供具体的价位和操作建议
- 早/晚各5分钟的检查清单
- 明确的风险管理规则

---

## Troubleshooting

**问题：没有图表图片**
→ 跳过图表分析，用 WebSearch + MCP 工具获取数据执行 Step 1

**问题：上周博客不存在**
→ 不做连续性检查，生成独立的首期博客

**问题：经济日历/财报日历获取失败**
→ 用 WebSearch 作为 fallback 获取事件信息

**问题：博客超过300行**
→ 精简各板块内容，优先保留操作建议，削减背景分析

---

## Important Notes

- 本技能为**编排型技能**，按顺序调用多个子技能完成工作流
- 每步完成后应向用户确认结果，再进入下一步
- 所有分析输出使用英文
- 这是教育和信息用途，不构成投资建议

---

**Version:** 2.0
**Last Updated:** 2026-02-23
**Execution Time:** ~15-30 分钟（含数据获取和分析）
**Output:** Markdown 博客文章 + 3份分析报告
**Dependencies:** 9个子技能 + WebSearch + FMP API
