# EventService

**层：** Kernel  
**文件：** `addons/mkit/kernel/events/event_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"events"`

## 职责

通用领域事件总线。kernel 只提供机制：发射 `DomainEvent`、按事件类型订阅、维护 `recent_events` 供调试回放。**事件定义归各模块所有**——事件类型常量与 payload 构造函数住在各模块的事件目录（`CombatEvents`、`QuestEvents`、`WorldEvents` 等），kernel 不知道任何具体业务事件。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `recent_events` | `Array[DomainEvent]` | `[]` | 最近 100 个领域事件（调试用）|
| `max_recent_events` | `int` | `100` | 容量上限 |

## 方法

| 方法签名 | 说明 |
|----------|------|
| `static find() -> EventService` | 经 ServiceRegistry 查找；未注册时返回 null |
| `emit_domain_event(event: DomainEvent) -> void` | 发送领域事件：记入 `recent_events`、发 `domain_event_emitted` 信号、分发给类型订阅者 |
| `emit_event(event_type, source_id = "", target_id = "", payload = {}) -> void` | 便捷包装：内联构造 `DomainEvent` 后发送 |
| `subscribe(event_type: String, callable: Callable) -> void` | 订阅某类型事件；回调签名 `func (event: DomainEvent)`；重复订阅为 no-op |
| `unsubscribe(event_type: String, callable: Callable) -> void` | 取消订阅 |
| `is_subscribed(event_type: String, callable: Callable) -> bool` | 查询订阅状态 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `domain_event_emitted` | `event: DomainEvent` | 每次 `emit_domain_event` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var events := Mkit.events()
events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)

func _on_entity_died(event: DomainEvent) -> void:
    print("Dead: %s" % event.payload.get("entity_id"))
```

### 典型场景（Level 2）

```gdscript
# 模块发射：用本模块事件目录构造事件
var events := Mkit.events()
if events != null:
    events.emit_domain_event(CombatEvents.entity_died(entity_id, owner))


# UI 层订阅多个事件
extends CanvasLayer

var _events: EventService = null


func _ready() -> void:
    _events = Mkit.events()
    if _events == null:
        push_error("EventService not available")
        return
    _events.subscribe(CombatEvents.DAMAGE_APPLIED, _on_damage_applied)
    _events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)
    _events.subscribe(QuestEvents.QUEST_COMPLETED, _on_quest_completed)


func _on_damage_applied(event: DomainEvent) -> void:
    var result: DamageResult = event.payload.get("result")
    _spawn_damage_number(result.final_amount, result.target)


func _on_entity_died(event: DomainEvent) -> void:
    if event.payload.get("entity_id") == "player":
        _show_game_over_screen()


func _on_quest_completed(event: DomainEvent) -> void:
    _show_quest_complete_banner(event.payload.get("quest_id"))


# 调试：检查最近事件列表
func _debug_recent_events() -> void:
    var events := Mkit.events()
    if events == null:
        return
    for ev in events.recent_events:
        print("[%s] source=%s target=%s" % [ev.event_type, ev.source_id, ev.target_id])
```

> 模块服务自身的类型化信号（如 `QuestService.quest_completed`、`ShopService.item_purchased`）仍然保留，需要编辑器补全时优先连接模块信号；总线用于跨模块解耦与调试回放。

## 相关

- → [DomainEvent](DomainEvent.md) — 事件对象结构
- → [CombatEvents](../modules/CombatEvents.md) / [QuestEvents](../modules/QuestEvents.md) / [WorldEvents](../modules/WorldEvents.md) — 模块事件目录
- → [pipeline.md — Event Notification](../../pipeline.md#8-event-notification)
- → [debugging.md](../../debugging.md) — recent_events 回放调试
- → [concepts.md — 模型 1：标准管线](../../concepts.md#模型-1标准管线时序图)（最后一跳）
