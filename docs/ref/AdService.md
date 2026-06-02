# AdService

## 概念说明

AdService 是广告平台接口。它检查广告是否就绪、展示广告并发出完成或失败信号。复活广告、奖励广告不能写死在 Run 或死亡流程里。

## 设计目的

提供一个平台无关的广告服务抽象接口，使 RunDirector 和死亡 UI 只依赖信号回调（rewarded_ad_completed/failed），具体广告 SDK 在子类中实现，开发期用 AdServiceMock 跑通流程。

## 文件

`res://addons/mkit/kernel/services/ad_service.gd`

## 接口

```gdscript
class_name AdService
extends Node

signal rewarded_ad_completed(placement_id: String)
signal rewarded_ad_failed(placement_id: String, reason: String)

func is_rewarded_ad_ready(placement_id: String) -> bool:
    return false

func show_rewarded_ad(placement_id: String) -> void:
    rewarded_ad_failed.emit(placement_id, "not_implemented")
```

## 函数使用场景

- **`is_rewarded_ad_ready(placement_id)`**：在显示广告按钮前调用，检查广告是否加载完毕。死亡界面据此决定是否显示"观看广告复活"按钮。
- **`show_rewarded_ad(placement_id)`**：触发广告播放。播放完成后发出 `rewarded_ad_completed`，播放失败时发出 `rewarded_ad_failed`。上层逻辑监听信号后执行奖励（如恢复 HP）。

## 使用示例

```gdscript
func offer_revive_ad() -> void:
    var ads := ServiceRegistry.get_service("ads") as AdService
    if ads.is_rewarded_ad_ready("revive"):
        ads.rewarded_ad_completed.connect(_on_revive_ad_completed)
        ads.show_rewarded_ad("revive")

func _on_revive_ad_completed(placement_id: String) -> void:
    if placement_id == "revive":
        $Player/Components/HealthComponent.revive(0.5)
```
