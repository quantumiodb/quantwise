---
name: market-breadth-analyzer
description: 使用TraderMonty的公开CSV数据量化市场广度健康状况。生成0-100的综合评分，涵盖6个维度（100 = 健康）。无需API密钥。当用户询问市场广度、参与率、涨跌线健康状况、上涨是否广泛，或整体市场健康评估时使用。
allowed-tools: [Bash(python3:*)]
---

# 市场广度分析器技能

## 目的

使用数据驱动的6维度评分系统（0-100）量化市场广度健康状况。利用TraderMonty公开可用的CSV数据，衡量市场在上涨或下跌中的参与广度。

**评分方向：** 100 = 最大健康度（广泛参与），0 = 严重虚弱。

**无需API密钥** - 使用GitHub Pages上免费提供的CSV数据。

## 何时使用本技能

**英文：**
- User asks "Is the market rally broad-based?" or "How healthy is market breadth?"
- User wants to assess market participation rate
- User asks about advance-decline indicators or breadth thrust
- User wants to know if the market is narrowing (fewer stocks participating)
- User asks about equity exposure levels based on breadth conditions

**中文：**
- "市场广度怎么样？""市场参与率如何？"
- "上涨范围广泛吗？""是不是只有少数股票在涨？"
- 基于广度指标判断仓位水平
- 希望用数据确认市场健康度

## 与Breadth Chart Analyst的区别

| 方面 | Market Breadth Analyzer | Breadth Chart Analyst |
|------|------------------------|----------------------|
| 数据来源 | CSV（自动化） | 图表图像（手动） |
| 需要API | 无 | 无 |
| 输出 | 定量0-100评分 | 定性图表分析 |
| 维度 | 6个评分维度 | 视觉模式识别 |
| 可重复性 | 完全可重现 | 依赖分析师 |

---

## 执行工作流

### 第一阶段：执行Python脚本

运行分析脚本：

```bash
python3 skills/market-breadth-analyzer/scripts/market_breadth_analyzer.py \
  --detail-url "https://tradermonty.github.io/market-breadth-analysis/market_breadth_data.csv" \
  --summary-url "https://tradermonty.github.io/market-breadth-analysis/market_breadth_summary.csv"
```

脚本将执行以下操作：
1. 获取详细CSV（约2,500行，2016年至今）和摘要CSV（8项指标）
2. 验证数据时效性（若超过5天则发出警告）
3. 计算所有6个维度的评分
4. 生成综合评分及区域分类
5. 输出JSON和Markdown报告

### 第二阶段：展示结果

向用户展示生成的Markdown报告，重点说明：
- 综合评分和健康区域
- 最强和最弱的维度
- 建议的股票仓位水平
- 需要关注的关键广度水平
- 任何数据时效性警告

---

## 6维度评分系统

| # | 维度 | 权重 | 关键信号 |
|---|------|------|----------|
| 1 | 广度水平与趋势 | **25%** | 当前8MA水平 + 200MA趋势方向 |
| 2 | 8MA与200MA交叉 | **20%** | 通过MA差距和方向判断动量 |
| 3 | 峰谷周期 | **20%** | 在广度周期中的位置 |
| 4 | 看跌信号 | **15%** | 经回测验证的看跌信号标志 |
| 5 | 历史百分位 | **10%** | 当前值与完整历史分布的对比 |
| 6 | S&P 500背离 | **10%** | 价格与广度的方向一致性 |

## 健康区域映射（100 = 健康）

| 评分 | 区域 | 股票仓位 | 行动 |
|------|------|----------|------|
| 80-100 | 强劲 | 90-100% | 满仓操作，偏向成长/动量 |
| 60-79 | 健康 | 75-90% | 正常操作 |
| 40-59 | 中性 | 60-75% | 精选持仓，收紧止损 |
| 20-39 | 转弱 | 40-60% | 获利了结，增加现金 |
| 0-19 | 危急 | 25-40% | 保存资本，关注谷底 |

---

## 数据来源

**详细CSV：** `market_breadth_data.csv`
- 约2,500行，从2016年2月至今
- 列：Date, S&P500_Price, Breadth_Index_Raw, Breadth_Index_200MA, Breadth_Index_8MA, Breadth_200MA_Trend, Bearish_Signal, Is_Peak, Is_Trough, Is_Trough_8MA_Below_04

**摘要CSV：** `market_breadth_summary.csv`
- 8项汇总指标（平均峰值、平均谷底、计数、分析期间）

两者均托管在GitHub Pages上——无需认证。

## 输出文件

- JSON: `market_breadth_YYYY-MM-DD_HHMMSS.json`
- Markdown: `market_breadth_YYYY-MM-DD_HHMMSS.md`

## 参考文档

### `references/breadth_analysis_methodology.md`
- 包含维度评分细节的完整方法论
- 阈值说明和区域定义
- 历史背景和解读指南

### 何时加载参考文档
- **首次使用：** 加载方法论参考文档以理解框架
- **常规执行：** 无需参考文档——脚本会处理评分
