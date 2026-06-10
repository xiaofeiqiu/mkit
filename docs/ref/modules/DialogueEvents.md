# DialogueEvents

**层：** Modules（dialogue）  
**文件：** `addons/mkit/modules/dialogue/dialogue_events.gd`  
**继承：** `extends RefCounted`

## 职责

dialogue 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `DIALOGUE_STARTED` | `"dialogue_started"` |
| `DIALOGUE_ENDED` | `"dialogue_ended"` |
| `NPC_TALKED` | `"npc_talked"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `dialogue_started(dialogue_id: String) -> DomainEvent` | payload 含 `dialogue_id` |
| `dialogue_ended(dialogue_id: String) -> DomainEvent` | payload 含 `dialogue_id` |
| `npc_talked(npc_id: String) -> DomainEvent` | payload 含 `npc_id`（`DialogueInteractable` 触发）|

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [DialogueService](DialogueService.md) / [DialogueInteractable](DialogueInteractable.md) — 发射方
