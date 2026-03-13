#!/usr/bin/env python3
"""
Bubble-O-Meter: 多维度评估美国股市泡沫程度的脚本

8个指标各评0-2分，合计(0-16分)判定泡沫程度:
- 0-4: 正常区
- 5-8: 警戒区
- 9-12: 狂热区
- 13-16: 临界区

使用方法:
    python bubble_scorer.py --ticker SPY --period 1y
"""

import argparse
import json
from datetime import datetime, timedelta
from typing import Dict, List, Tuple


class BubbleScorer:
    """泡沫评分系统"""

    def __init__(self):
        self.indicators = {
            "mass_penetration": {
                "name": "大众渗透度",
                "weight": 2,
                "description": "非投资者群体的推荐和提及"
            },
            "media_saturation": {
                "name": "媒体饱和度",
                "weight": 2,
                "description": "搜索、社交媒体、媒体曝光的急剧上升"
            },
            "new_accounts": {
                "name": "新增入场",
                "weight": 2,
                "description": "开户数和资金流入的加速"
            },
            "new_issuance": {
                "name": "新发行泛滥",
                "weight": 2,
                "description": "IPO/SPAC/相关产品的泛滥"
            },
            "leverage": {
                "name": "杠杆",
                "weight": 2,
                "description": "保证金、信用、融资利率的偏离"
            },
            "price_acceleration": {
                "name": "价格加速度",
                "weight": 2,
                "description": "收益率达到历史分布上游"
            },
            "valuation_disconnect": {
                "name": "估值脱离",
                "weight": 2,
                "description": "基本面解释完全依赖叙事"
            },
            "breadth_expansion": {
                "name": "相关性与广度",
                "weight": 2,
                "description": "低质量个股也全面上涨"
            }
        }

    def calculate_score(self, scores: Dict[str, int]) -> Dict:
        """
        从各指标分数计算综合评估

        Args:
            scores: 各指标分数字典 (0-2分)

        Returns:
            评估结果字典
        """
        total_score = sum(scores.values())
        max_score = len(self.indicators) * 2

        # 泡沫阶段判定
        if total_score <= 4:
            phase = "正常区"
            risk_level = "低"
            action = "继续正常投资策略"
        elif total_score <= 8:
            phase = "警戒区"
            risk_level = "中"
            action = "开始部分止盈，缩小新仓位规模"
        elif total_score <= 12:
            phase = "狂热区"
            risk_level = "高"
            action = "加速阶梯式止盈，严格ATR追踪止损，总风险预算削减30-50%"
        else:
            phase = "临界区"
            risk_level = "极高"
            action = "大幅止盈或全额对冲，停止新入场，确认反转后考虑做空仓位"

        # Minsky阶段估计
        minsky_phase = self._estimate_minsky_phase(scores, total_score)

        return {
            "timestamp": datetime.now().isoformat(),
            "total_score": total_score,
            "max_score": max_score,
            "percentage": round(total_score / max_score * 100, 1),
            "phase": phase,
            "risk_level": risk_level,
            "minsky_phase": minsky_phase,
            "recommended_action": action,
            "indicator_scores": scores,
            "detailed_indicators": self._format_indicator_details(scores)
        }

    def _estimate_minsky_phase(self, scores: Dict[str, int], total: int) -> str:
        """Minsky/Kindleberger阶段估计"""
        mass_pen = scores.get("mass_penetration", 0)
        media = scores.get("media_saturation", 0)
        price_acc = scores.get("price_acceleration", 0)

        if total <= 4:
            return "Displacement/Early Boom (触发/初期扩张)"
        elif total <= 8:
            if media >= 1 and price_acc >= 1:
                return "Boom (扩张期)"
            else:
                return "Displacement/Early Boom (触发/初期扩张)"
        elif total <= 12:
            if mass_pen >= 2 and media >= 2:
                return "Euphoria (狂热期) - FOMO已制度化"
            else:
                return "Late Boom/Early Euphoria (扩张后期/狂热初期)"
        else:
            if mass_pen >= 2:
                return "Peak Euphoria/Profit Taking (狂热顶峰/止盈开始) - 临近反转"
            else:
                return "Euphoria (狂热期)"

    def _format_indicator_details(self, scores: Dict[str, int]) -> List[Dict]:
        """格式化指标详细信息"""
        details = []
        for key, value in scores.items():
            indicator = self.indicators.get(key, {})
            status = "🔴高" if value == 2 else "🟡中" if value == 1 else "🟢低"
            details.append({
                "indicator": indicator.get("name", key),
                "score": value,
                "status": status,
                "description": indicator.get("description", "")
            })
        return details

    def get_scoring_guidelines(self) -> str:
        """返回各指标的评分指南"""
        guidelines = """
## 泡沫评分指南

### 1. 大众渗透度 (Mass Penetration)
- 0分: 仅限专家和投资者群体讨论
- 1分: 普通人也有认知，但作为投资标的仍有限
- 2分: 非投资者（出租车司机、美容师、家人）积极推荐和提及

### 2. 媒体饱和度 (Media Saturation)
- 0分: 正常水平的报道和搜索趋势
- 1分: 搜索趋势、社交媒体提及为平时的2-3倍
- 2分: 电视专题、杂志封面、搜索趋势暴涨（平时的5倍以上）

### 3. 新增入场 (New Accounts & Inflows)
- 0分: 正常水平的开户和入金
- 1分: 开户数同比增长50-100%
- 2分: 开户数同比增长200%以上，大量"首次投资"人群涌入

### 4. 新发行泛滥 (New Issuance Flood)
- 0分: 正常水平的IPO/产品发行
- 1分: IPO/SPAC/相关ETF同比增长50%以上
- 2分: 低质量IPO泛滥，"XX概念"基金/ETF滥造

### 5. 杠杆 (Leverage Indicators)
- 0分: 保证金余额、信用损益在正常范围
- 1分: 保证金余额为历史均值的1.5倍，期货持仓偏离
- 2分: 保证金余额创历史新高，融资利率居高不下，极端持仓偏离

### 6. 价格加速度 (Price Acceleration)
- 0分: 年化收益率在历史分布的中位数附近
- 1分: 年化收益率超过历史90百分位
- 2分: 年化收益率达到历史95-99百分位，或加速度（二阶导数）为正且递增

### 7. 估值脱离 (Valuation Disconnect)
- 0分: 可用基本面合理解释
- 1分: 高估值但可用"成长预期"勉强解释
- 2分: 解释完全依赖"叙事""革命""范式转换"，"这次不一样"

### 8. 相关性与广度 (Breadth & Correlation)
- 0分: 仅部分领涨股上涨
- 1分: 扩散至整个板块，mid-cap也上涨
- 2分: 低质量/low-cap个股也全面上涨，"僵尸企业"也上涨（最后的买家入场）
"""
        return guidelines

    def format_output(self, result: Dict) -> str:
        """将结果格式化为可读输出"""
        output = f"""
{'='*60}
🔍 美国市场泡沫度评估 - Bubble-O-Meter
{'='*60}

评估时间: {result['timestamp']}

【综合评分】
{result['total_score']}/{result['max_score']}分 ({result['percentage']}%)

【市场阶段】
当前: {result['phase']} (风险: {result['risk_level']})
Minsky阶段: {result['minsky_phase']}

【建议操作】
{result['recommended_action']}

{'='*60}
【各指标评分】
{'='*60}
"""
        for detail in result['detailed_indicators']:
            output += f"\n{detail['status']} {detail['indicator']}: {detail['score']}/2分\n"
            output += f"   └─ {detail['description']}\n"

        output += f"\n{'='*60}\n"

        return output


def manual_assessment() -> Dict[str, int]:
    """交互式手动评估"""
    scorer = BubbleScorer()
    print("\n" + "="*60)
    print("🔍 美国市场泡沫度评估 - Manual Assessment")
    print("="*60)
    print("\n请对各指标评0-2分:")
    print(scorer.get_scoring_guidelines())

    scores = {}
    for key, indicator in scorer.indicators.items():
        while True:
            try:
                score = int(input(f"\n{indicator['name']} (0-2): "))
                if 0 <= score <= 2:
                    scores[key] = score
                    break
                else:
                    print("请输入0、1或2")
            except ValueError:
                print("请输入数字")

    return scores


def main():
    parser = argparse.ArgumentParser(
        description="评估美国市场泡沫程度的Bubble-O-Meter"
    )
    parser.add_argument(
        "--manual",
        action="store_true",
        help="交互式手动评估模式"
    )
    parser.add_argument(
        "--scores",
        type=str,
        help="JSON格式的分数字符串 (例: '{\"mass_penetration\":2,\"media_saturation\":1,...}')"
    )
    parser.add_argument(
        "--output",
        choices=["text", "json"],
        default="text",
        help="输出格式"
    )

    args = parser.parse_args()
    scorer = BubbleScorer()

    # 获取分数
    if args.manual:
        scores = manual_assessment()
    elif args.scores:
        try:
            scores = json.loads(args.scores)
        except json.JSONDecodeError:
            print("错误: 无效的JSON格式")
            return 1
    else:
        print("错误: 请指定 --manual 或 --scores")
        print("\n显示指南:")
        print(scorer.get_scoring_guidelines())
        return 1

    # 执行评估
    result = scorer.calculate_score(scores)

    # 输出
    if args.output == "json":
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(scorer.format_output(result))

    return 0


if __name__ == "__main__":
    exit(main())
