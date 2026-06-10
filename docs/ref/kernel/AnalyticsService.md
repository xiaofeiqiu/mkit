# AnalyticsService

**层：** Kernel（平台适配层）  
**文件：** `addons/mkit/kernel/services/analytics_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"analytics"`（默认注册 `AnalyticsServiceMock`）

## 职责

数据统计的平台适配抽象。基类是 no-op 接口；`GameBootstrap` 默认注册 `AnalyticsServiceMock`（打印到控制台）。接入真实 SDK（如 GA / Firebase）时，继承本类实现方法，在 Bootstrap 里替换注册。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `track_event(event_name: String, properties := {}) -> void` | — | 上报事件 |
| `set_user_property(key: String, value: Variant) -> void` | — | 设用户属性 |

## AnalyticsServiceMock

**文件：** `addons/mkit/kernel/services/analytics_service_mock.gd` · `extends AnalyticsService`  
开发期默认实现：`track_event` / `set_user_property` 仅 `print`，便于在控制台看埋点是否触发。

## 使用模式

### 最小示例（Level 1）

```gdscript
var analytics := Mkit.analytics()
analytics.track_event("level_complete", {"level": 3, "time": 42.0})
```

### 替换为真实实现（Level 2）

```gdscript
class_name MyBootstrap
extends GameBootstrap

func _register_kernel_services() -> void:
    super._register_kernel_services()
    var real := MyFirebaseAnalytics.new()   # 你的 AnalyticsService 子类
    ServiceRegistry.register_service("analytics", real)   # 覆盖默认 Mock
```

## 相关

- → [GameBootstrap](GameBootstrap.md)（注册/替换点）· [architecture.md — 平台适配层](../../architecture.md)
