# AnalyticsServiceMock

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/analytics_service_mock.gd`  
**继承：** `extends AnalyticsService`  
**服务 ID：** `"analytics"`（`GameBootstrap` 默认注册）

## 职责

默认统计适配器。把事件和用户属性打印到控制台，便于本地确认埋点路径，不依赖第三方 SDK。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `track_event(event_name: String, properties: Dictionary = {}) -> void` | — | 打印事件名和属性 |
| `set_user_property(key: String, value: Variant) -> void` | — | 打印用户属性键值 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var analytics: AnalyticsService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_ANALYTICS) as AnalyticsService
analytics.track_event("run_started", {"seed": 1234})
```

### 典型场景（Level 2）

```gdscript
func track_run_finished(result: String, floor: int) -> void:
    var analytics: AnalyticsService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_ANALYTICS) as AnalyticsService
    if analytics == null:
        return
    analytics.track_event("run_finished", {"result": result, "floor": floor})
    analytics.set_user_property("last_run_result", result)
```

## 相关

- → [AnalyticsService](AnalyticsService.md) · [EventService](EventService.md)

