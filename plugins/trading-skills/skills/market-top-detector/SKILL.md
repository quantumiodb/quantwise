---
name: market-top-detector
description: 使用O'Neil派发日、Minervini领涨股恶化和Monty防御板块轮动来检测市场顶部概率。生成0-100的综合评分并进行风险区域分类。当用户询问市场顶部风险、派发日、防御轮动、领涨股崩溃，或是否应减少股票仓位时使用。专注于2-8周战术时机信号，预测10-20%的调整。
---

# 市场顶部检测器技能

## 目的

使用定量的6维度评分系统（0-100）检测市场顶部形成的概率。整合三种经过验证的市场顶部检测方法论：

1. **O'Neil** - 派发日累积（机构卖出）
2. **Minervini** - 领涨股恶化模式
3. **Monty** - 防御板块轮动信号

与泡沫检测器（宏观/多月评估）不同，本技能专注于**战术性的2-8周时机信号**，这些信号先于10-20%的市场调整出现。

## 何时使用本技能

**英文：**
- User asks "Is the market topping?" or "Are we near a top?"
- User notices distribution days accumulating
- User observes defensive sectors outperforming growth
- User sees leading stocks breaking down while indices hold
- User asks about reducing equity exposure timing
- User wants to assess correction probability for the next 2-8 weeks

**中文：**
- "市场接近顶部了吗？""现在应该获利了结吗？"
- 担忧派发日的累积
- 防御板块跑赢成长板块
- 领涨股开始崩溃而指数仍在支撑
- 减仓时机的判断
- 想要评估未来2-8周的调整概率

## 与泡沫检测器的区别

| 方面 | Market Top Detector | Bubble Detector |
|------|-------------------|-----------------|
| 时间框架 | 2-8周 | 数月至数年 |
| 目标 | 10-20%调整 | 泡沫破裂（30%+） |
| 方法论 | O'Neil/Minervini/Monty | Minsky/Kindleberger |
| 数据 | 价格/成交量 + 广度 | 估值 + 情绪 + 社会 |
| 评分范围 | 0-100综合评分 | 0-15分 |

---

## 执行工作流

### 第一阶段：通过WebSearch收集数据

在运行Python脚本之前，使用WebSearch收集以下数据：

```
1. S&P 500广度（高于200日均线的占比）：
   搜索："S&P 500 stocks above 200 day moving average percent"
   来源：Barchart、MarketInOut 或 StockCharts

2. S&P 500广度（高于50日均线的占比）：
   搜索："S&P 500 stocks above 50 day moving average percent"

3. CBOE股票Put/Call比率：
   搜索："CBOE equity put call ratio current"

4. VIX期限结构：
   搜索："VIX term structure contango backwardation"
   分类为：steep_contango / contango / flat / backwardation

5.（可选）保证金债务：
   搜索："FINRA margin debt latest year over year"
```

### 第二阶段：执行Python脚本

使用收集的数据作为CLI参数运行脚本：

```bash
python3 skills/market-top-detector/scripts/market_top_detector.py \
  --api-key $FMP_API_KEY \
  --breadth-200dma [VALUE] \
  --breadth-50dma [VALUE] \
  --put-call [VALUE] \
  --vix-term [steep_contango|contango|flat|backwardation] \
  --margin-debt-yoy [VALUE] \
  --context "Consumer Confidence=[VALUE]" "Gold Price=[VALUE]"
```

脚本将执行以下操作：
1. 从FMP API获取S&P 500、QQQ、VIX的报价和历史数据
2. 获取领涨ETF（ARKK、WCLD、IGV、XBI、SOXX、SMH、KWEB、TAN）数据
3. 获取板块ETF（XLU、XLP、XLV、VNQ、XLK、XLC、XLY）数据
4. 计算所有6个维度
5. 生成综合评分和报告

### 第三阶段：展示结果

向用户展示生成的Markdown报告，重点说明：
- 综合评分和风险区域
- 最强的警告信号（最高维度评分）
- 基于风险区域的建议行动
- Follow-Through Day状态（如适用）

---

## 6维度评分系统

| # | 维度 | 权重 | 数据来源 | 关键信号 |
|---|------|------|----------|----------|
| 1 | 派发日计数 | **25%** | FMP API | 过去25个交易日的机构卖出 |
| 2 | 领涨股健康度 | **20%** | FMP API | 成长ETF组合恶化 |
| 3 | 防御板块轮动 | **15%** | FMP API | 防御 vs 成长相对表现 |
| 4 | 市场广度背离 | **15%** | WebSearch | 200日/50日均线广度 vs 指数水平 |
| 5 | 指数技术状态 | **15%** | FMP API | 均线结构、反弹失败、更低高点 |
| 6 | 情绪与投机 | **10%** | FMP + WebSearch | VIX、Put/Call、期限结构 |

## 风险区域映射

| 评分 | 区域 | 风险预算 | 行动 |
|------|------|----------|------|
| 0-20 | 绿色（正常） | 100% | 正常操作 |
| 21-40 | 黄色（早期预警） | 80-90% | 收紧止损，减少新建仓位 |
| 41-60 | 橙色（风险升高） | 60-75% | 对弱势仓位获利了结 |
| 61-80 | 红色（顶部高概率） | 40-55% | 积极获利了结 |
| 81-100 | 危急（顶部形成中） | 20-35% | 最大防御，对冲 |

---

## API要求

**必需：** FMP API密钥（免费层即可：每次执行约33次调用）
**可选：** WebSearch数据用于广度和情绪（提高准确性）

## 输出文件

- JSON: `market_top_YYYY-MM-DD_HHMMSS.json`
- Markdown: `market_top_YYYY-MM-DD_HHMMSS.md`

## 参考文档

### `references/market_top_methodology.md`
- 包含O'Neil、Minervini和Monty框架的完整方法论
- 维度评分细节和阈值
- 历史验证说明

### `references/distribution_day_guide.md`
- O'Neil派发日规则详解
- 停滞日识别
- Follow-Through Day（FTD）机制

### `references/historical_tops.md`
- 2000年、2007年、2018年、2022年市场顶部分析
- 历史顶部期间的维度评分模式
- 经验教训和校准数据

### 何时加载参考文档
- **首次使用：** 加载 `market_top_methodology.md` 以全面理解框架
- **派发日问题：** 加载 `distribution_day_guide.md`
- **历史背景：** 加载 `historical_tops.md`
- **常规执行：** 无需参考文档——脚本会处理评分
