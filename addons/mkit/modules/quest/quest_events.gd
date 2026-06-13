class_name QuestEvents
extends RefCounted
## 任务领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `QUEST_ACCEPTED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const QUEST_ACCEPTED := "quest_accepted"
## 稳定标识 `QUEST_OBJECTIVE_ADVANCED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const QUEST_OBJECTIVE_ADVANCED := "quest_objective_advanced"
## 稳定标识 `QUEST_COMPLETED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const QUEST_COMPLETED := "quest_completed"
## 稳定标识 `QUEST_TURNED_IN`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const QUEST_TURNED_IN := "quest_turned_in"
## 用于击杀类目标；QuestService 会基于 CombatEvents.ENTITY_DIED 合成该事件。
const ENEMY_KILLED := "enemy_killed"


## 执行 `quest_accepted` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func quest_accepted(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_ACCEPTED, quest_id, "", {"quest_id": quest_id})


## 执行 `quest_objective_advanced` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func quest_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> DomainEvent:
	return DomainEvent.create(
		QUEST_OBJECTIVE_ADVANCED,
		quest_id,
		objective_id,
		{"quest_id": quest_id, "objective_id": objective_id, "current": current, "required": required}
	)


## 执行 `quest_completed` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func quest_completed(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_COMPLETED, quest_id, "", {"quest_id": quest_id})


## 执行 `quest_turned_in` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func quest_turned_in(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_TURNED_IN, quest_id, "", {"quest_id": quest_id})
