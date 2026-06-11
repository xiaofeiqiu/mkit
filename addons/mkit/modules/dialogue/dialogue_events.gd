class_name DialogueEvents
extends RefCounted
## 对话领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `DIALOGUE_STARTED`，作为 `DialogueEvents` 对外暴露的类型、事件或命令标识。
const DIALOGUE_STARTED := "dialogue_started"
## 公开常量 `DIALOGUE_ENDED`，作为 `DialogueEvents` 对外暴露的类型、事件或命令标识。
const DIALOGUE_ENDED := "dialogue_ended"
## 公开常量 `NPC_TALKED`，作为 `DialogueEvents` 对外暴露的类型、事件或命令标识。
const NPC_TALKED := "npc_talked"


## 执行 `dialogue_started` 对应的公开操作，并保持 `DialogueEvents` 的领域契约一致。
static func dialogue_started(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_STARTED, dialogue_id, "", {"dialogue_id": dialogue_id})


## 执行 `dialogue_ended` 对应的公开操作，并保持 `DialogueEvents` 的领域契约一致。
static func dialogue_ended(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_ENDED, dialogue_id, "", {"dialogue_id": dialogue_id})


## 执行 `npc_talked` 对应的公开操作，并保持 `DialogueEvents` 的领域契约一致。
static func npc_talked(npc_id: String) -> DomainEvent:
	return DomainEvent.create(NPC_TALKED, npc_id, "", {"npc_id": npc_id})
