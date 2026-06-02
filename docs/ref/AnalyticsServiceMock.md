# AnalyticsServiceMock

## 概念说明

AnalyticsServiceMock 是 AnalyticsService 的开发期假实现。它把埋点事件打印到控制台，而不是发送到真实统计平台。在接入真实 SDK 前，就能验证 run_started、reward_selected、death 等事件有没有被正确触发。

## 设计目的

提供一个零依赖的 AnalyticsService 实现，使开发团队可以在无网络或无 SDK 环境下验证所有埋点调用的时机和字段是否正确，然后在发布前替换为真实实现，无需修改玩法代码。

## 文件

`res://addons/mkit/kernel/services/analytics_service_mock.gd`

## 接口

```gdscript
class_name AnalyticsServiceMock
extends AnalyticsService
func track_event(event_name: String, properties: Dictionary = {}) -> void
func set_user_property(key: String, value: Variant) -> void
```

## 函数使用场景

- **`track_event(event_name, properties)`**：覆写父类方法，将事件名和属性格式化打印到控制台。开发和测试阶段调试埋点完整性，无需连接真实统计后台。

## 使用示例

### 在 Bootstrap 中注册 mock

```gdscript
func _register_platform_services() -> void:
    var analytics := AnalyticsServiceMock.new()
    add_child(analytics)
    ServiceRegistry.register_service("analytics", analytics)
```

### 控制台输出示例

```text
[Analytics] run_started { run_id: run_123, seed: 12345, character: warrior }
[Analytics] reward_selected { reward_id: reward.attack_plus_20, rarity: common }
[Analytics] run_finished { run_id: run_123, result: completed }
```
