# 周交易策略博客 - 项目指南

本项目是一个用于自动生成美股周交易策略博客的系统。

## 项目结构

```
weekly-trade-strategy/
├── charts/              # 图表图片存储文件夹
│   └── YYYY-MM-DD/     # 按日期分类的文件夹
│       ├── chart1.jpeg
│       └── chart2.jpeg
│
├── reports/            # 分析报告存储文件夹
│   └── YYYY-MM-DD/    # 按日期分类的文件夹
│       ├── technical-market-analysis.md
│       ├── us-market-analysis.md
│       └── market-news-analysis.md
│
├── blogs/              # 最终博客文章存储文件夹
│   └── YYYY-MM-DD-weekly-strategy.md
│
└── .claude/
    ├── agents/         # 智能体定义
    └── skills/         # 技能定义
```

## 周刊博客创建的标准流程

### 步骤0：准备

1. **放置图表图片**
   ```bash
   # 创建本周日期文件夹
   mkdir -p charts/2025-11-03

   # 放置图表图片（推荐18张）
   # - VIX（周线）
   # - 美国10年期国债收益率（周线）
   # - S&P 500 Breadth Index（200日均线 + 8日均线）
   # - Nasdaq 100（周线）
   # - S&P 500（周线）
   # - Russell 2000（周线）
   # - Dow Jones（周线）
   # - 黄金期货（周线）
   # - 铜期货（周线）
   # - 原油（周线）
   # - 天然气（周线）
   # - 铀ETF（URA，周线）
   # - Uptrend Stock Ratio（全市场）
   # - 板块表现（1周）
   # - 板块表现（1个月）
   # - 行业表现（涨幅/跌幅排名）
   # - 财报日历
   # - 主要个股热力图
   ```

2. **创建报告输出文件夹**
   ```bash
   mkdir -p reports/2025-11-03
   ```

### 步骤1：Technical Market Analysis

**目的**：分析图表图片，通过技术指标评估市场环境

**智能体**：`technical-market-analyst`

**输入**：
- `charts/YYYY-MM-DD/*.jpeg`（所有图表图片）

**输出**：
- `reports/YYYY-MM-DD/technical-market-analysis.md`

**执行命令示例**：
```
请使用technical-market-analyst智能体执行本周（2025-11-03）的图表分析。
分析charts/2025-11-03/中的所有图表，并将报告保存至reports/2025-11-03/technical-market-analysis.md。
```

**分析内容**：
- VIX、10年期国债收益率、Breadth指标的当前值和评估
- 主要指数（Nasdaq、S&P500、Russell2000、Dow）的技术分析
- 大宗商品（黄金、铜、原油、铀）的趋势分析
- 板块轮动分析
- 按情景的概率评估

---

### 步骤2：US Market Analysis

**目的**：市场环境综合评估和泡沫风险检测

**智能体**：`us-market-analyst`

**输入**：
- `reports/YYYY-MM-DD/technical-market-analysis.md`（步骤1的结果）
- 市场数据（VIX、Breadth、利率等）

**输出**：
- `reports/YYYY-MM-DD/us-market-analysis.md`

**执行命令示例**：
```
请使用us-market-analyst智能体执行美国市场综合分析。
参考reports/2025-11-03/technical-market-analysis.md，
评估市场环境和泡沫风险，保存至reports/2025-11-03/us-market-analysis.md。
```

**分析内容**：
- 当前市场阶段（Risk-On / Base / Caution / Stress）
- 泡沫检测评分（0-16评分体系）
- 板块轮动模式
- 波动率状态
- 风险因素和催化剂

---

### 步骤3：Market News Analysis

**目的**：过去10天的新闻影响分析和未来7天的事件预测

**智能体**：`market-news-analyzer`

**输入**：
- `reports/YYYY-MM-DD/technical-market-analysis.md`（步骤1的结果）
- `reports/YYYY-MM-DD/us-market-analysis.md`（步骤2的结果）
- 经济日历、财报日历

**输出**：
- `reports/YYYY-MM-DD/market-news-analysis.md`

**执行命令示例**：
```
请使用market-news-analyzer智能体执行新闻和事件分析。
分析过去10天的新闻影响和未来7天的重要事件，
保存至reports/2025-11-03/market-news-analysis.md。
```

**分析内容**：
- 过去10天的主要新闻及其对市场的影响
- 未来7天的经济指标发布日程
- 主要财报发布（市值$2B以上）
- 按事件的情景分析（附概率）
- 风险事件的优先级排序

---

### 步骤4：Weekly Blog Generation

**目的**：整合3份报告，生成面向兼职交易者的周策略博客

**智能体**：`weekly-trade-blog-writer`

**输入**：
- `reports/YYYY-MM-DD/technical-market-analysis.md`
- `reports/YYYY-MM-DD/us-market-analysis.md`
- `reports/YYYY-MM-DD/market-news-analysis.md`
- `blogs/`（上周的博客文章，用于连续性检查）

**输出**：
- `blogs/YYYY-MM-DD-weekly-strategy.md`

**执行命令示例**：
```
请使用weekly-trade-blog-writer智能体创建2025年11月3日当周的博客文章。
整合reports/2025-11-03/下的3份报告，
保持与上周板块配置的连续性，
保存至blogs/2025-11-03-weekly-strategy.md。
```

**文章结构**（200-300行）：
1. **3句话总结** - 市场环境、焦点、策略
2. **本周操作** - 仓位管理、买卖水平、板块配置、重要事件
3. **情景计划** - Base/Risk-On/Caution的3种情景
4. **市场状况** - 统一触发指标（10Y/VIX/Breadth）
5. **商品与板块策略** - 黄金/铜/铀/原油
6. **兼职交易指南** - 早/晚检查清单
7. **风险管理** - 本周特有风险
8. **总结** - 3-5句话

**重要约束**：
- 与上周的板块配置变动**控制在+-10-15%以内**（渐进式调整）
- 在历史新高+Base触发条件下，避免大幅削减仓位
- 现金配置应渐进增加（例：10% -> 20-25% -> 30-35%）

---

### 步骤5（可选）：Druckenmiller Strategy Planning

**目的**：整合3份分析报告，制定18个月中长期投资战略

**智能体**：`druckenmiller-strategy-planner`

**输入**：
- `reports/YYYY-MM-DD/technical-market-analysis.md`（步骤1的结果）
- `reports/YYYY-MM-DD/us-market-analysis.md`（步骤2的结果）
- `reports/YYYY-MM-DD/market-news-analysis.md`（步骤3的结果）
- 上一期Druckenmiller战略报告（如存在）

**输出**：
- `reports/YYYY-MM-DD/druckenmiller-strategy.md`

**执行命令示例**：
```
请使用druckenmiller-strategy-planner智能体制定截至2025年11月3日的18个月战略。
综合分析reports/2025-11-03/下的3份报告，
应用Druckenmiller风格的战略框架，
保存至reports/2025-11-03/druckenmiller-strategy.md。
```

**分析框架**：

1. **Druckenmiller的投资哲学**
   - 以宏观为核心的18个月前瞻分析
   - 基于确信度的仓位管理
   - 多因素叠加时的集中投资
   - 快速止损和灵活应变

2. **4种情景分析**（附概率）
   - **Base Case**（最高概率情景）
   - **Bull Case**（乐观情景）
   - **Bear Case**（风险情景）
   - **Tail Risk**（低概率极端情景）

3. **各情景的构成要素**
   - 主要催化剂（政策、经济、地缘政治）
   - 时间线（Q1-Q2、Q3-Q4的演进）
   - 各资产类别的影响
   - 最优持仓策略
   - 失效信号（策略转换的触发条件）

**报告结构**（约150-200行）：
```markdown
# Strategic Investment Outlook - [Date]

## Executive Summary
[2-3段：主导主题和战略持仓的摘要]

## Market Context & Current Environment
### Macroeconomic Backdrop
[货币政策、经济周期、宏观指标现状]

### Technical Market Structure
[主要技术水平、趋势、形态]

### Sentiment & Positioning
[市场情绪、机构持仓、逆向投资机会]

## 18-Month Scenario Analysis

### Base Case Scenario (XX% probability)
**Narrative:** [最可能的市场走势路径]
**Key Catalysts:**
- [催化剂1]
- [催化剂2]
**Timeline Markers:**
- [Q1-Q2预期走势]
- [Q3-Q4预期走势]
**Strategic Positioning:**
- [资产配置建议]
- [具体交易方案及确信度]
**Risk Management:**
- [失效信号]
- [止损/退出标准]

### Bull Case Scenario (XX% probability)
[与Base Case相同结构]

### Bear Case Scenario (XX% probability)
[与Base Case相同结构]

### Tail Risk Scenario (XX% probability)
[与Base Case相同结构]

## Recommended Strategic Actions

### High Conviction Trades
[技术、基本面、情绪三者叠加的交易]

### Medium Conviction Positions
[风险/回报良好但因素叠合度较低的持仓]

### Hedges & Protective Strategies
[风险管理持仓和组合保险]

### Watchlist & Contingent Trades
[等待确认或特定触发条件的布局]

## Key Monitoring Indicators
[情景验证/失效的跟踪指标]

## Conclusion & Next Review Date
[最终战略建议和下次评审时间]
```

**重要特征**：
- 与周刊博客（短期战术）不同，这是**18个月的中长期战略**
- 重点关注宏观经济的结构变化和政策转折点
- 基于确信度的仓位管理（High/Medium/Low）
- 每个情景设定明确的失效条件
- 使用stanley-druckenmiller-investment技能

**执行时机**：
- 与周刊博客同步执行（建议每季度一次）
- FOMC等重大事件后
- 市场结构的重大转折点

**缺失报告的自动生成**：
上游报告（步骤1-3）不存在时，druckenmiller-strategy-planner将自动调用缺失的智能体。

---

## 一键执行脚本（推荐）

```bash
# 设置日期
DATE="2025-11-03"

# 步骤0：准备文件夹
mkdir -p charts/$DATE reports/$DATE

# 步骤1-4一键执行的提示词示例：
「请创建$DATE当周的交易策略博客。

1. 使用technical-market-analyst分析charts/$DATE/的所有图表
   → reports/$DATE/technical-market-analysis.md

2. 使用us-market-analyst综合评估市场环境
   → reports/$DATE/us-market-analysis.md

3. 使用market-news-analyzer分析新闻/事件
   → reports/$DATE/market-news-analysis.md

4. 使用weekly-trade-blog-writer生成最终博客文章
   → blogs/$DATE-weekly-strategy.md

请按顺序执行各步骤，确认报告后再进入下一步。」
```

---

## 智能体间的数据流

### 周刊博客生成流程

```
charts/YYYY-MM-DD/
  ├─> [technical-market-analyst]
  │      └─> reports/YYYY-MM-DD/technical-market-analysis.md
  │            │
  │            ├─> [us-market-analyst]
  │            │      └─> reports/YYYY-MM-DD/us-market-analysis.md
  │            │            │
  │            │            ├─> [market-news-analyzer]
  │            │            │      └─> reports/YYYY-MM-DD/market-news-analysis.md
  │            │            │            │
  │            └────────────┴────────────┴─> [weekly-trade-blog-writer]
  │                                                └─> blogs/YYYY-MM-DD-weekly-strategy.md
  │
  └─> (同时参考上周的博客文章)
       blogs/YYYY-MM-DD-weekly-strategy.md (上周)
```

### 中长期战略报告生成流程（可选）

```
reports/YYYY-MM-DD/
  ├─> technical-market-analysis.md ────┐
  ├─> us-market-analysis.md ───────────┼─> [druckenmiller-strategy-planner]
  └─> market-news-analysis.md ─────────┘      └─> reports/YYYY-MM-DD/druckenmiller-strategy.md
                                                       (18个月投资战略)
```

---

## 故障排除

### 智能体无法找到图表
- 确认`charts/YYYY-MM-DD/`文件夹是否存在
- 确认图表图片文件格式是否为`.jpeg`或`.png`

### 报告未生成
- 确认`reports/YYYY-MM-DD/`文件夹是否存在
- 确认上一步的报告是否正常生成

### 博客文章的板块配置发生剧变
- 确认`blogs/`中是否存在上周的博客文章
- 确认weekly-trade-blog-writer智能体的连续性检查功能是否生效

### 博客文章过长（超过300行）
- 确认weekly-trade-blog-writer智能体定义中的长度限制
- 文章生成后，检查行数：`wc -l blogs/YYYY-MM-DD-weekly-strategy.md`

---

## 推荐工作流程

### 周日晚间（中国时间）或周五晚间（美国时间）
1. 周末准备图表
2. 运行technical-market-analyst
3. 确认结果后进入下一步

### 周一早间
4. 运行us-market-analyst、market-news-analyzer
5. 审阅3份报告
6. 使用weekly-trade-blog-writer生成博客
7. 最终审阅并发布

---

## 各智能体的详细规格

### technical-market-analyst
- **技能**：technical-analyst, breadth-chart-analyst, sector-analyst
- **分析对象**：周线图表、Breadth指标、板块表现
- **输出格式**：Markdown，附情景概率

### us-market-analyst
- **技能**：market-environment-analysis, us-market-bubble-detector
- **分析对象**：市场阶段、泡沫评分、情绪
- **输出格式**：Markdown，风险评估

### market-news-analyzer
- **技能**：market-news-analyst, economic-calendar-fetcher, earnings-calendar
- **分析对象**：过去10天新闻、未来7天事件
- **输出格式**：Markdown，按事件情景分析

### weekly-trade-blog-writer
- **输入**：上述3份报告 + 上周博客
- **约束**：200-300行，渐进式调整（+-10-15%）
- **输出格式**：面向兼职交易者的Markdown（5-10分钟阅读）

### druckenmiller-strategy-planner（可选）
- **技能**：stanley-druckenmiller-investment
- **分析对象**：18个月中长期宏观战略、情景分析
- **输入**：上述3份报告（technical, us-market, market-news）
- **输出格式**：Markdown，4种情景（Base/Bull/Bear/Tail Risk），附概率和确信度
- **特征**：Druckenmiller风格的集中投资和快速止损，宏观转折点识别
- **执行频率**：每季度一次，或FOMC等重大事件后

---

## 版本管理

- **项目版本**：1.0
- **最后更新日期**：2025-11-02
- **维护**：请定期更新本文档

---

## 联系与反馈

有关本工作流程的改进建议或问题报告，请提交至项目的Issue跟踪器。
