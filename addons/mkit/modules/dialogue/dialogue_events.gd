class_name DialogueEvents
extends RefCounted
## 对话领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `DIALOGUE_STARTED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const DIALOGUE_STARTED := "dialogue_started"
## 稳定标识 `DIALOGUE_ENDED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const DIALOGUE_ENDED := "dialogue_ended"
## 稳定标识 `NPC_TALKED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const NPC_TALKED := "npc_talked"


## 执行 `dialogue_started` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func dialogue_started(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_STARTED, dialogue_id, "", {"dialogue_id": dialogue_id})


## 执行 `dialogue_ended` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func dialogue_ended(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_ENDED, dialogue_id, "", {"dialogue_id": dialogue_id})


## 执行 `npc_talked` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func npc_talked(npc_id: String) -> DomainEvent:
	return DomainEvent.create(NPC_TALKED, npc_id, "", {"npc_id": npc_id})
