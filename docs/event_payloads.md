# Event Payloads

本页列出 mkit 内置模块公开发布的固定 `DomainEvent` 类型与 payload key。`EventService.emit_event()`、`LogEffect.event_type` 和游戏侧自定义事件是开放扩展点，不在这个固定目录中。

读取 payload 时仍应使用 `event.payload.get("key", default)`，因为部分 key 只在有对应上下文时出现。

## 事件目录

| 事件目录 / 来源 | event_type | source_id | target_id | payload keys |
| --- | --- | --- | --- | --- |
| `CombatEvents.DAMAGE_APPLIED` | `damage_applied` | 伤害来源实体 id | 受击目标实体 id | `base_amount`, `final_amount`, `damage_type`, `element_type`, `critical`, `evaded`, `blocked`, `lethal`, `applied_status_effects`, `trace`, `result` |
| `CombatEvents.ENTITY_DIED` | `entity_died` | 死亡实体 id | none | `entity_id`, `entity_ref`, `killer_id`, `killer_ref`, `tags`, `faction`, `definition_id`, `killer_tags`, `killer_faction`, `killer_definition_id` |
| `DialogueEvents.DIALOGUE_STARTED` | `dialogue_started` | 对话 id | none | `dialogue_id` |
| `DialogueEvents.DIALOGUE_ENDED` | `dialogue_ended` | 对话 id | none | `dialogue_id` |
| `DialogueEvents.NPC_TALKED` | `npc_talked` | NPC id | none | `npc_id` |
| `InventoryEvents.INVENTORY_CHANGED` | `inventory_changed` | 拥有者实体 id | 物品 id 或空 | `owner_id`, `item_id`, `quantity`, `change_type` |
| `LootEvents.REWARD_SELECTED` | `reward_selected` | 选择来源 id 或空 | none | `reward_id` |
| `LootEvents.LOOT_DROPPED` | `loot_dropped` | 死亡实体 id | 击杀者实体 id 或空 | `drop` |
| `QuestEvents.QUEST_ACCEPTED` | `quest_accepted` | 任务 id | none | `quest_id` |
| `QuestEvents.QUEST_OBJECTIVE_ADVANCED` | `quest_objective_advanced` | 任务 id | 目标 id | `quest_id`, `objective_id`, `current`, `required` |
| `QuestEvents.QUEST_COMPLETED` | `quest_completed` | 任务 id | none | `quest_id` |
| `QuestEvents.QUEST_TURNED_IN` | `quest_turned_in` | 任务 id | none | `quest_id` |
| `QuestEvents.ENEMY_KILLED` | `enemy_killed` | 死亡实体 id | none | `entity_id`, `tags`, `faction`, `definition_id` |
| `QuestService` synthetic item event | `item_acquired` | 背包拥有者实体 id | 物品 id | `owner_id`, `item_id`, `quantity`, `change_type`, `amount` |
| `ShopEvents.ITEM_PURCHASED` | `item_purchased` | 商店 id | 物品 id | `shop_id`, `item_id`, `quantity` |
| `ShopEvents.ITEM_SOLD` | `item_sold` | 商店 id | 物品 id | `shop_id`, `item_id`, `quantity` |
| `WorldEvents.ROOM_CLEARED` | `room_cleared` | 房间 runtime id | none | none |
| `WorldEvents.ZONE_CHANGED` | `zone_changed` | 来源 zone id | 目标 zone id | `from_zone_id`, `to_zone_id` |
| `WorldService` zone entry event | `zone_entered` | 当前 zone id | none | `zone_id` |
| `WorldEvents.RUN_STARTED` | `run_started` | run id | none | `seed` |
| `WorldEvents.RUN_FINISHED` | `run_finished` | run id | none | `result` |

## 使用边界

- 新的内置模块事件应优先放进对应 `XxxEvents` 目录类，定义常量和静态构造函数。
- 新的公开固定事件需要同步更新本页；`make docs-check` 会校验事件名与 payload key。
- 调试事件、游戏侧事件和临时 effect 事件可以继续用自由 `event_type`，不需要加入本页。
