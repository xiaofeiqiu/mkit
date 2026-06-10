# CombatEvents

**层：** Modules（combat）  
**文件：** `addons/mkit/modules/combat/combat_events.gd`  
**继承：** `extends RefCounted`

## 职责

combat 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。kernel 的 [EventService](../kernel/EventService.md) 只提供总线机制，事件定义归本模块所有。

## 常量

| 常量 | 值 |
|------|-----|
| `DAMAGE_APPLIED` | `"damage_applied"` |
| `ENTITY_DIED` | `"entity_died"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `damage_applied(result: DamageResult) -> DomainEvent` | payload 为 `result.to_debug_dict()` 加 `result`（对象引用）；source/target 取双方实体 id |
| `entity_died(entity_id: String, entity_ref: Node) -> DomainEvent` | payload 含 `entity_id`、`entity_ref`，实体有 `EntityIdentity` 时附 `tags` / `faction` / `definition_id` |
| `entity_id_of(entity: Node) -> String` | 经 `EntityContract` 解析实体 id，失败时回退节点名 |

## 使用模式

```gdscript
# 发射（HealthComponent 内部即如此）
var events := Mkit.events()
if events != null:
    events.emit_domain_event(CombatEvents.entity_died(entity_id, owner))

# 订阅
events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)

func _on_entity_died(event: DomainEvent) -> void:
    print("%s died" % event.payload.get("entity_id"))
```

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [HealthComponent](HealthComponent.md) — 两个事件的发射方
- → [DamageResult](DamageResult.md)
