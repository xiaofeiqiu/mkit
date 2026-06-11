class_name QuestEvents
extends RefCounted
## 任务领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `QUEST_ACCEPTED`，作为 `QuestEvents` 对外暴露的类型、事件或命令标识。
const QUEST_ACCEPTED := "quest_accepted"
## 公开常量 `QUEST_OBJECTIVE_ADVANCED`，作为 `QuestEvents` 对外暴露的类型、事件或命令标识。
const QUEST_OBJECTIVE_ADVANCED := "quest_objective_advanced"
## 公开常量 `QUEST_COMPLETED`，作为 `QuestEvents` 对外暴露的类型、事件或命令标识。
const QUEST_COMPLETED := "quest_completed"
## 公开常量 `QUEST_TURNED_IN`，作为 `QuestEvents` 对外暴露的类型、事件或命令标识。
const QUEST_TURNED_IN := "quest_turned_in"
## 用于击杀类目标；QuestService 会基于 CombatEvents.ENTITY_DIED 合成该事件。
const ENEMY_KILLED := "enemy_killed"


## 执行 `quest_accepted` 对应的公开操作，并保持 `QuestEvents` 的领域契约一致。
static func quest_accepted(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_ACCEPTED, quest_id, "", {"quest_id": quest_id})


## 执行 `quest_objective_advanced` 对应的公开操作，并保持 `QuestEvents` 的领域契约一致。
static func quest_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> DomainEvent:
	return DomainEvent.create(
		QUEST_OBJECTIVE_ADVANCED,
		quest_id,
		objective_id,
		{"quest_id": quest_id, "objective_id": objective_id, "current": current, "required": required}
	)


## 执行 `quest_completed` 对应的公开操作，并保持 `QuestEvents` 的领域契约一致。
static func quest_completed(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_COMPLETED, quest_id, "", {"quest_id": quest_id})


## 执行 `quest_turned_in` 对应的公开操作，并保持 `QuestEvents` 的领域契约一致。
static func quest_turned_in(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_TURNED_IN, quest_id, "", {"quest_id": quest_id})
