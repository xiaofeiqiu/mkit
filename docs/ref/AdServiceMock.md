# AdServiceMock

## 概念说明

AdServiceMock 是 AdService 的开发期假实现。它模拟广告已准备好、播放完成、奖励发放等回调，不依赖真实广告 SDK。复活广告和奖励广告流程可以先在编辑器中跑通，不必等移动广告 SDK 接入完成。

## 设计目的

提供一个零依赖的 AdService 实现，使开发团队可以在无广告 SDK 环境下验证复活流程、奖励发放和 UI 交互，然后在移动端发布时替换为真实实现，无需修改上层逻辑。

## 文件

`res://addons/mkit/kernel/services/ad_service_mock.gd`

## 接口

```gdscript
class_name AdServiceMock
extends AdService
func is_rewarded_ad_ready(_placement_id: String) -> bool
func show_rewarded_ad(placement_id: String) -> void
```

## 函数使用场景

- **`is_rewarded_ad_ready(placement_id)`**：始终返回 true，模拟广告已加载完毕，使死亡 UI 总是显示复活按钮。
- **`show_rewarded_ad(placement_id)`**：等待 0.5 秒后发出 `rewarded_ad_completed`，模拟广告播放完成的延迟回调，使上层流程（恢复 HP、关闭 UI）可以完整测试。

## 使用示例

### 在 Bootstrap 中注册 mock

```gdscript
func _register_mock_ads() -> void:
    var ads := AdServiceMock.new()
    add_child(ads)
    ServiceRegistry.register_service("ads", ads)
```

### 测试 rewarded ad 流程

```gdscript
var ads := ServiceRegistry.get_service("ads") as AdService
ads.rewarded_ad_completed.connect(func(id): print("Mock ad completed: ", id))
ads.show_rewarded_ad("revive")
# 0.5 秒后打印: "Mock ad completed: revive"
```
