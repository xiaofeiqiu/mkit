# DomainEvent

## 概念说明

DomainEvent 是已经发生的玩法事实的通知对象。负责承载 damage_applied、entity_died、inventory_changed、room_cleared、run_started 等事件，并将这些事实广播给关心它的监听者。UI、音效、VFX、Analytics 和 Debug 都需要知道发生了什么，但不应该直接依赖 Combat、Inventory 或 Room 的内部实现。

## 设计目的

Event 表示已经发生的事实，用过去式命名。DomainEvent 只用于通知，不用于请求别人做事。监听者可以选择性地响应特定事件类型，发送者无需知道监听者的存在。

## 文件

`res://addons/mkit/kernel/events/domain_event.gd`

## 接口

```gdscript
class_name DomainEvent
extends RefCounted

var event_type: String = ""
var event_id: String = ""
var timestamp: float = 0.0
var source_id: String = ""
var target_id: String = ""
var payload: Dictionary = {}

static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> DomainEvent
```

## 函数使用场景

- **create()**：工厂方法，一次性设置所有必要字段。例：HealthComponent 确认敌人死亡后，用 `DomainEvent.create("entity_died", entity_id)` 创建事件，保证 event_id 和 timestamp 自动生成不遗漏。

## 使用示例

### 创建一个通用事件

```gdscript
var event := DomainEvent.create(
    "item_collected",
    "player_001",
    "",
    {
        "item_id": "item.sword_iron",
        "quantity": 1
    }
)
```

### 通过 EventRouter 发出事件

```gdscript
var events := ServiceRegistry.get_service("events") as EventRouter
if events != null:
    events.emit_domain_event(event)
```
