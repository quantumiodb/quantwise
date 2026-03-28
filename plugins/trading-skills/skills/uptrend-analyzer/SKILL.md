---
name: uptrend-analyzer
description: 使用Monty的上升趋势比率仪表盘数据分析市场广度，诊断当前市场环境。从5个维度（广度、板块参与度、轮动、动量、历史背景）生成0-100的综合评分。当询问市场广度、上升趋势比率，或市场环境是否支持股票仓位时使用。无需API密钥。
allowed-tools: [Bash(python3:*)]
---

# 上升趋势分析器技能

## 目的

使用Monty的上升趋势比率仪表盘诊断市场广度健康状况，该仪表盘跟踪约2,800只美股和11个板块。生成0-100的综合评分（越高越健康），并提供仓位建议。

与Market Top Detector（基于API的风险评分器）不同，本技能使用免费的CSV数据评估"参与广度"——即市场的上涨是广泛的还是狭窄的。

## 何时使用本技能

**英文：**
- User asks "Is the market breadth healthy?" or "How broad is the rally?"
- User wants to assess uptrend ratios across sectors
- User asks about market participation or breadth conditions
- User needs exposure guidance based on breadth analysis
- User references Monty's Uptrend Dashboard or uptrend ratios

**中文：**
- "市场广度健康吗？""上涨范围广泛吗？"
- 想要查看各板块的上升趋势比率
- 想要诊断市场参与率和广度状况
- 需要基于广度分析的仓位指导建议
- 关于Monty的上升趋势仪表盘的问题

## 与Market Top Detector的区别

| 方面 | Uptrend Analyzer | Market Top Detector |
|------|-----------------|-------------------|
| 评分方向 | 越高越健康 | 越高越危险 |
| 数据来源 | 免费GitHub CSV | FMP API（付费） |
| 关注点 | 广度参与度 | 顶部形成风险 |
| API密钥 | 不需要 | 需要（FMP） |
| 方法论 | Monty上升趋势比率 | O'Neil/Minervini/Monty |

---

## 执行工作流

### 第一阶段：执行Python脚本

运行分析脚本（无需API密钥）：

```bash
python3 skills/uptrend-analyzer/scripts/uptrend_analyzer.py
```

脚本将执行以下操作：
1. 从Monty的GitHub仓库下载CSV数据
2. 计算5个维度的评分
3. 生成综合评分和报告

### 第二阶段：展示结果

向用户展示生成的Markdown报告，重点说明：
- 综合评分和区域分类
- 仓位建议（满仓/正常/减仓/防御/保存资本）
- 板块热力图，显示最强和最弱的板块
- 关键动量和轮动信号

---

## 5维度评分系统

| # | 维度 | 权重 | 关键信号 |
|---|------|------|----------|
| 1 | 市场广度（整体） | **30%** | 比率水平 + 趋势方向 |
| 2 | 板块参与度 | **25%** | 处于上升趋势的板块数量 + 比率离散度 |
| 3 | 板块轮动 | **15%** | 周期性 vs 防御性板块平衡 |
| 4 | 动量 | **20%** | 斜率方向 + 加速度 |
| 5 | 历史背景 | **10%** | 在历史中的百分位排名 |

## 评分区域

| 评分 | 区域 | 仓位建议 |
|------|------|----------|
| 80-100 | 强牛市 | 满仓（100%） |
| 60-79 | 牛市 | 正常仓位（80-100%） |
| 40-59 | 中性 | 减仓（60-80%） |
| 20-39 | 谨慎 | 防御性（30-60%） |
| 0-19 | 熊市 | 保存资本（0-30%） |

---

## API要求

**必需：** 无（使用免费的GitHub CSV数据）

## 输出文件

- JSON: `uptrend_analysis_YYYY-MM-DD_HHMMSS.json`
- Markdown: `uptrend_analysis_YYYY-MM-DD_HHMMSS.md`

## 参考文档

### `references/uptrend_methodology.md`
- 上升趋势比率的定义和阈值
- 5维度评分方法论
- 板块分类（周期性/防御性/大宗商品）
- 历史校准说明

### 何时加载参考文档
- **首次使用：** 加载 `uptrend_methodology.md` 以全面理解框架
- **常规执行：** 无需参考文档——脚本会处理评分
