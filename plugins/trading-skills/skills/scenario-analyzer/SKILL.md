---
name: scenario-analyzer
description: |
  以新闻标题为输入分析18个月情景的技能。
  通过scenario-analyst代理执行主分析，
  通过strategy-reviewer代理获取第二意见。
  生成包含一级、二级、三级影响、推荐股票和评审的综合报告，以中文输出。
  使用示例: /scenario-analyzer "Fed raises rates by 50bp"
  触发条件: 新闻分析、情景分析、18个月展望、中长期投资策略
allowed-tools: [WebSearch, WebFetch]
---

# 标题情景分析器

## 概述

本技能以新闻标题为起点，分析中长期（18个月）的投资情景。
依次调用两个专业代理（`scenario-analyst`和`strategy-reviewer`），
生成整合多角度分析和批判性评审的综合报告。

## 何时使用本技能

在以下情况下使用本技能：

- 想从新闻标题分析中长期投资影响
- 想构建18个月后的多个情景
- 想按一级/二级/三级分类整理对板块和个股的影响
- 需要包含第二意见的综合分析
- 需要中文报告输出

**使用示例：**
```
/headline-scenario-analyzer "Fed raises interest rates by 50bp, signals more hikes ahead"
/headline-scenario-analyzer "China announces new tariffs on US semiconductors"
/headline-scenario-analyzer "OPEC+ agrees to cut oil production by 2 million barrels per day"
```

## 架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Skill（编排器）                                    │
│                                                                      │
│  Phase 1: 准备                                                       │
│  ├─ 标题解析                                                         │
│  ├─ 事件类型分类                                                     │
│  └─ 参考资料加载                                                     │
│                                                                      │
│  Phase 2: 代理调用                                                   │
│  ├─ scenario-analyst（主分析）                                       │
│  └─ strategy-reviewer（第二意见）                                    │
│                                                                      │
│  Phase 3: 整合与报告生成                                             │
│  └─ reports/scenario_analysis_<topic>_YYYYMMDD.md                   │
└─────────────────────────────────────────────────────────────────────┘
```

## 工作流程

### Phase 1: 准备

#### 步骤1.1: 标题解析

解析用户输入的标题。

1. **标题确认**
   - 确认是否作为参数传入了标题
   - 如未传入则要求用户输入

2. **关键词提取**
   - 主要实体（公司名、国名、机构名）
   - 数值数据（利率、价格、数量）
   - 动作（上调、下调、发布、达成协议等）

#### 步骤1.2: 事件类型分类

将标题分为以下类别：

| 类别 | 示例 |
|---------|-----|
| 货币政策 | FOMC、ECB、日本央行、加息、降息、QE/QT |
| 地缘政治 | 战争、制裁、关税、贸易摩擦 |
| 监管与政策 | 环境法规、金融监管、反垄断法 |
| 科技 | AI、EV、可再生能源、半导体 |
| 大宗商品 | 原油、黄金、铜、农产品 |
| 企业与并购 | 收购、破产、财报、行业重组 |

#### 步骤1.3: 参考资料加载

根据事件类型加载相关参考资料：

```
Read references/headline_event_patterns.md
Read references/sector_sensitivity_matrix.md
Read references/scenario_playbooks.md
```

**参考资料内容：**
- `headline_event_patterns.md`: 过去的事件模式和市场反应
- `sector_sensitivity_matrix.md`: 事件×板块的影响度矩阵
- `scenario_playbooks.md`: 情景构建模板和最佳实践

---

### Phase 2: 代理调用

#### 步骤2.1: 调用scenario-analyst

使用Task tool调用主分析代理。

```
Task tool:
- subagent_type: "scenario-analyst"
- prompt: |
    请针对以下标题执行18个月情景分析。

    ## 目标标题
    [输入的标题]

    ## 事件类型
    [分类结果]

    ## 参考信息
    [已加载参考资料的摘要]

    ## 分析要求
    1. 通过WebSearch收集过去2周的相关新闻
    2. 构建Base/Bull/Bear三个情景（概率合计100%）
    3. 按板块分析一级/二级/三级影响
    4. 选定正面/负面影响各3-5只股票（仅限美国市场）
    5. 全部以中文输出
```

**期望输出：**
- 相关新闻文章列表
- 三个情景（Base/Bull/Bear）的详细内容
- 板块影响分析（一级/二级/三级）
- 股票推荐列表

#### 步骤2.2: 调用strategy-reviewer

收到scenario-analyst的分析结果后，调用评审代理。

```
Task tool:
- subagent_type: "strategy-reviewer"
- prompt: |
    请评审以下情景分析。

    ## 目标标题
    [输入的标题]

    ## 分析结果
    [scenario-analyst的完整输出]

    ## 评审要求
    从以下角度进行评审：
    1. 被遗漏的板块/股票
    2. 情景概率分配的合理性
    3. 影响分析的逻辑一致性
    4. 乐观/悲观偏差的检测
    5. 替代情景的建议
    6. 时间线的现实性

    请以中文输出建设性且具体的反馈。
```

**期望输出：**
- 遗漏指出
- 对情景概率的意见
- 偏差指出
- 替代情景建议
- 最终建议

---

### Phase 3: 整合与报告生成

#### 步骤3.1: 结果整合

整合两个代理的输出，形成最终投资判断。

**整合要点：**
1. 补充评审中指出的遗漏
2. 调整概率分配（如有必要）
3. 考虑偏差后的最终判断
4. 制定具体的行动计划

#### 步骤3.2: 报告生成

以以下格式生成最终报告并保存到文件。

**保存路径：** `reports/scenario_analysis_<topic>_YYYYMMDD.md`

```markdown
# 标题情景分析报告

**分析日期**: YYYY-MM-DD HH:MM
**目标标题**: [输入的标题]
**事件类型**: [分类类别]

---

## 1. 相关新闻文章
[scenario-analyst收集的新闻列表]

## 2. 预期情景概要（至18个月后）

### Base Case（XX%概率）
[情景详情]

### Bull Case（XX%概率）
[情景详情]

### Bear Case（XX%概率）
[情景详情]

## 3. 对板块和行业的影响

### 一级影响（直接）
[影响表格]

### 二级影响（价值链与相关产业）
[影响表格]

### 三级影响（宏观、监管、技术）
[影响表格]

## 4. 预计受正面影响的股票（3-5只）
[股票表格]

## 5. 预计受负面影响的股票（3-5只）
[股票表格]

## 6. 第二意见与评审
[strategy-reviewer的输出]

## 7. 最终投资判断与启示

### 推荐行动
[综合评审后的具体行动]

### 风险因素
[主要风险列举]

### 监控要点
[需要跟踪的指标和事件]

---
**生成工具**: scenario-analyzer skill
**代理**: scenario-analyst, strategy-reviewer
```

#### 步骤3.3: 报告保存

1. 如果`reports/`目录不存在则创建
2. 保存为`scenario_analysis_<topic>_YYYYMMDD.md`（例如：`scenario_analysis_venezuela_20260104.md`）
3. 通知用户保存完成
4. **不要直接保存在项目根目录**

---

## 资源

### 参考资料
- `references/headline_event_patterns.md` - 事件模式和市场反应
- `references/sector_sensitivity_matrix.md` - 板块敏感度矩阵
- `references/scenario_playbooks.md` - 情景构建模板

### 代理
- `scenario-analyst` - 主情景分析
- `strategy-reviewer` - 第二意见与评审

---

## 重要说明

### 语言
- 所有分析和输出均以**中文**进行
- 股票代码保持英文表记

### 目标市场
- 股票选择**仅限美国市场上市股票**
- 包含ADR

### 时间轴
- 情景涵盖**18个月**
- 以0-6个月/6-12个月/12-18个月三个阶段描述

### 概率分配
- Base + Bull + Bear = **100%**
- 每个情景的概率须附带依据

### 第二意见
- **必须**执行（始终调用strategy-reviewer）
- 评审结果反映在最终判断中

### 输出目录（重要）
- **必须**保存在`reports/`目录下
- 路径：`reports/scenario_analysis_<topic>_YYYYMMDD.md`
- 示例：`reports/scenario_analysis_fed_rate_hike_20260104.md`
- 如果`reports/`目录不存在则创建
- **不得直接保存在项目根目录**

---

## 质量检查清单

报告完成前确认以下事项：

- [ ] 标题是否正确解析
- [ ] 事件类型分类是否恰当
- [ ] 三个情景的概率合计是否为100%
- [ ] 一级/二级/三级影响是否有逻辑关联
- [ ] 股票选择是否有具体依据
- [ ] 是否包含strategy-reviewer的评审
- [ ] 是否记载了综合评审后的最终判断
- [ ] 报告是否保存在正确路径
