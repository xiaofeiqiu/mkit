# AnalyticsService

## 概念说明

AnalyticsService 是玩法数据埋点接口。它记录 run_started、reward_selected、death、purchase 等结构化事件。玩法代码不应该依赖某个具体统计 SDK。

## 设计目的

提供一个平台无关的分析服务抽象接口，使玩法代码（RunDirector、RewardSystem）只通过 `track_event()` 发送埋点，实际 SDK（Firebase、GameAnalytics 等）在具体实现类中对接，开发期可用 AnalyticsServiceMock 替换。

## 文件

`res://addons/mkit/kernel/services/analytics_service.gd`

## 接口

```gdscript
class_name AnalyticsService
extends Node

func track_event(event_name: String, properties: Dictionary = {}) -> void:
    pass

func set_user_property(key: String, value) -> void:
    pass
```

## 函数使用场景

- **`track_event(event_name, properties)`**：记录一次玩法事件，properties 包含结构化属性（run_id、seed、floor 等）。RunDirector 在 run_started 和 run_finished 时调用，RewardSystem 在 reward_selected 时调用。
- **`set_user_property(key, value)`**：设置用户级别的属性（如 total_runs、max_floor），供留存和行为分析使用。

## 使用示例

```gdscript
var analytics := ServiceRegistry.get_service("analytics") as AnalyticsService
analytics.track_event("run_started", {
    "run_id": run_state.run_id,
    "seed": run_state.seed,
    "character": "warrior"
})

analytics.track_event("reward_selected", {
    "reward_id": option.reward_id,
    "rarity": option.rarity,
    "floor": run_state.current_floor
})
```
