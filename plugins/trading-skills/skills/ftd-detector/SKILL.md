---
name: ftd-detector
description: 检测Follow-Through Day（FTD）信号以确认市场底部，采用William O'Neil的方法论。双指数跟踪（S&P 500 + NASDAQ），使用状态机进行反弹尝试、FTD确认和FTD后健康监控。当用户询问市场底部信号、Follow-Through Day、反弹尝试、调整后的重新入场时机，或是否可以安全增加股票仓位时使用。与market-top-detector（防御性）互补——本技能为进攻性（底部确认）。
---

# FTD检测器技能

## 目的

检测确认市场底部的Follow-Through Day（FTD）信号，采用William O'Neil经过验证的方法论。生成质量评分（0-100），并提供重新进入市场的仓位建议。

**与Market Top Detector互补：**
- Market Top Detector = 防御性（检测派发、轮动、恶化）
- FTD Detector = 进攻性（检测反弹尝试、底部确认）

## 何时使用本技能

**英文：**
- User asks "Is the market bottoming?" or "Is it safe to buy again?"
- User observes a market correction (3%+ decline) and wants re-entry timing
- User asks about Follow-Through Days or rally attempts
- User wants to assess if a recent bounce is sustainable
- User asks about increasing equity exposure after a correction
- Market Top Detector shows elevated risk and user wants bottom signals

**中文：**
- "市场见底了吗？""可以重新买入了吗？"
- 调整行情（3%以上的下跌）后的入场时机判断
- 关于Follow-Through Day或反弹尝试的问题
- 想要评估近期反弹是否可持续
- 调整后是否应增加仓位的判断
- Market Top Detector显示高风险后，确认底部信号

## 与Market Top Detector的区别

| 方面 | FTD Detector | Market Top Detector |
|------|-------------|-------------------|
| 关注点 | 底部确认（进攻性） | 顶部检测（防御性） |
| 触发条件 | 市场调整（3%+下跌） | 市场处于/接近高点 |
| 信号 | 反弹尝试 → FTD → 重新入场 | 派发 → 恶化 → 退出 |
| 评分 | 0-100 FTD质量 | 0-100 顶部概率 |
| 行动 | 何时增加仓位 | 何时减少仓位 |

---

## 执行工作流

### 第一阶段：执行Python脚本

运行FTD检测器脚本：

```bash
python3 skills/ftd-detector/scripts/ftd_detector.py --api-key $FMP_API_KEY
```

脚本将执行以下操作：
1. 从FMP API获取S&P 500和QQQ的历史数据（60+个交易日）
2. 获取两个指数的当前报价
3. 运行双指数状态机（调整 → 反弹 → FTD检测）
4. 评估FTD后的健康状况（派发日、失效、强势趋势）
5. 计算质量评分（0-100）
6. 生成JSON和Markdown报告

**API预算：** 4次调用（完全在免费层250次/天的范围内）

### 第二阶段：展示结果

向用户展示生成的Markdown报告，重点说明：
- 当前市场状态（调整、反弹尝试、FTD已确认等）
- 质量评分和信号强度
- 建议的仓位水平
- 关键观察水平（摆动低点、FTD当日低点）
- FTD后的健康状况（派发日、强势趋势）

### 第三阶段：情境化指导

根据市场状态提供额外指导：

**如果FTD已确认（评分60+）：**
- 建议关注处于正确形态的领涨股
- 参考CANSLIM筛选器寻找候选股票
- 提醒注意仓位大小和止损

**如果处于反弹尝试阶段（第1-3天）：**
- 建议耐心等待，不要在FTD之前买入
- 建议构建观察列表

**如果没有调整：**
- FTD分析在上升趋势中不适用
- 转向Market Top Detector获取防御性信号

---

## 状态机

```
NO_SIGNAL → CORRECTION → RALLY_ATTEMPT → FTD_WINDOW → FTD_CONFIRMED
                ↑              ↓               ↓              ↓
                └── RALLY_FAILED ←─────────────┘     FTD_INVALIDATED
```

| 状态 | 定义 |
|------|------|
| NO_SIGNAL | 上升趋势，无符合条件的调整 |
| CORRECTION | 3%+的下跌，伴随3+个下跌日 |
| RALLY_ATTEMPT | 从摆动低点开始的第1-3天反弹 |
| FTD_WINDOW | 第4-10天，等待符合条件的FTD |
| FTD_CONFIRMED | 检测到有效的FTD信号 |
| RALLY_FAILED | 反弹跌破摆动低点 |
| FTD_INVALIDATED | 收盘价低于FTD当日低点 |

## 质量评分（0-100）

| 评分 | 信号 | 仓位 |
|------|------|------|
| 80-100 | 强FTD | 75-100% |
| 60-79 | 中等FTD | 50-75% |
| 40-59 | 弱FTD | 25-50% |
| <40 | 无FTD / 失败 | 0-25% |

---

## API要求

**必需：** FMP API密钥（免费层即可：每次执行4次调用）

## 输出文件

- JSON: `ftd_detector_YYYY-MM-DD_HHMMSS.json`
- Markdown: `ftd_detector_YYYY-MM-DD_HHMMSS.md`

## 参考文档

### `references/ftd_methodology.md`
- O'Neil的FTD规则详解
- 反弹尝试机制和天数计算
- 历史FTD案例（2020年3月、2022年10月）

### `references/post_ftd_guide.md`
- FTD后派发日失败率
- 强势趋势（Power Trend）的定义和条件
- 成功与失败模式对比

### 何时加载参考文档
- **首次使用：** 加载 `ftd_methodology.md` 以全面理解
- **FTD后的问题：** 加载 `post_ftd_guide.md`
- **常规执行：** 无需参考文档——脚本会处理分析
