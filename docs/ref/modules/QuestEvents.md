# QuestEvents

**层：** Modules（quest）  
**文件：** `addons/mkit/modules/quest/quest_events.gd`  
**继承：** `extends RefCounted`

## 职责

quest 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `QUEST_ACCEPTED` | `"quest_accepted"` |
| `QUEST_OBJECTIVE_ADVANCED` | `"quest_objective_advanced"` |
| `QUEST_COMPLETED` | `"quest_completed"` |
| `QUEST_TURNED_IN` | `"quest_turned_in"` |
| `ENEMY_KILLED` | `"enemy_killed"`（QuestService 由 `CombatEvents.ENTITY_DIED` 合成，供击杀目标匹配）|

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `quest_accepted(quest_id: String) -> DomainEvent` | payload 含 `quest_id` |
| `quest_objective_advanced(quest_id, objective_id, current, required) -> DomainEvent` | payload 含全部进度字段 |
| `quest_completed(quest_id: String) -> DomainEvent` | payload 含 `quest_id` |
| `quest_turned_in(quest_id: String) -> DomainEvent` | payload 含 `quest_id` |

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [QuestService](QuestService.md) — 发射方；其类型化信号（`quest_accepted` 等）依旧保留
