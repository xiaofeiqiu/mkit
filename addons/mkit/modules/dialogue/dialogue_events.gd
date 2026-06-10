class_name DialogueEvents
extends RefCounted
## Dialogue-owned domain event catalog: event type constants + DomainEvent constructors.

const DIALOGUE_STARTED := "dialogue_started"
const DIALOGUE_ENDED := "dialogue_ended"
const NPC_TALKED := "npc_talked"


static func dialogue_started(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_STARTED, dialogue_id, "", {"dialogue_id": dialogue_id})


static func dialogue_ended(dialogue_id: String) -> DomainEvent:
	return DomainEvent.create(DIALOGUE_ENDED, dialogue_id, "", {"dialogue_id": dialogue_id})


static func npc_talked(npc_id: String) -> DomainEvent:
	return DomainEvent.create(NPC_TALKED, npc_id, "", {"npc_id": npc_id})
