class_name LootEvents
extends RefCounted
## 掉落领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `REWARD_SELECTED`，作为 `LootEvents` 对外暴露的类型、事件或命令标识。
const REWARD_SELECTED := "reward_selected"
## 公开常量 `LOOT_DROPPED`，作为 `LootEvents` 对外暴露的类型、事件或命令标识。
const LOOT_DROPPED := "loot_dropped"


## 执行 `reward_selected` 对应的公开操作，并保持 `LootEvents` 的领域契约一致。
static func reward_selected(reward_id: String, source_id: String = "") -> DomainEvent:
	return DomainEvent.create(REWARD_SELECTED, source_id, "", {"reward_id": reward_id})


## 执行 `loot_dropped` 对应的公开操作，并保持 `LootEvents` 的领域契约一致。
static func loot_dropped(drop: LootDropResult) -> DomainEvent:
	var source_id := ""
	var target_id := ""
	if drop != null:
		source_id = drop.entity_id
		target_id = drop.killer_id
	return DomainEvent.create(LOOT_DROPPED, source_id, target_id, {"drop": drop})
