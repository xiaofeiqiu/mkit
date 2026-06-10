# LootEvents

**层：** Modules（loot）  
**文件：** `addons/mkit/modules/loot/loot_events.gd`  
**继承：** `extends RefCounted`

## 职责

loot 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `REWARD_SELECTED` | `"reward_selected"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `reward_selected(reward_id: String, source_id = "") -> DomainEvent` | payload 含 `reward_id`；source 为选择来源（如宝箱实体名）|

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [RewardSystem](RewardSystem.md) — 发射方
