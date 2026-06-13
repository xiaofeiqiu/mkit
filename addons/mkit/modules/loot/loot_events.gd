class_name LootEvents
extends RefCounted
## 掉落领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `REWARD_SELECTED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const REWARD_SELECTED := "reward_selected"
## 稳定标识 `LOOT_DROPPED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const LOOT_DROPPED := "loot_dropped"


## 执行 `reward_selected` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func reward_selected(reward_id: String, source_id: String = "") -> DomainEvent:
	return DomainEvent.create(REWARD_SELECTED, source_id, "", {"reward_id": reward_id})


## 执行 `loot_dropped` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func loot_dropped(drop: LootDropResult) -> DomainEvent:
	var source_id := ""
	var target_id := ""
	if drop != null:
		source_id = drop.entity_id
		target_id = drop.killer_id
	return DomainEvent.create(LOOT_DROPPED, source_id, target_id, {"drop": drop})
