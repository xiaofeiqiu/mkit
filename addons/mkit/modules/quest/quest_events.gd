class_name QuestEvents
extends RefCounted
## Quest-owned domain event catalog: event type constants + DomainEvent constructors.

const QUEST_ACCEPTED := "quest_accepted"
const QUEST_OBJECTIVE_ADVANCED := "quest_objective_advanced"
const QUEST_COMPLETED := "quest_completed"
const QUEST_TURNED_IN := "quest_turned_in"
## Synthesized by QuestService from CombatEvents.ENTITY_DIED for kill objectives.
const ENEMY_KILLED := "enemy_killed"


static func quest_accepted(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_ACCEPTED, quest_id, "", {"quest_id": quest_id})


static func quest_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> DomainEvent:
	return DomainEvent.create(
		QUEST_OBJECTIVE_ADVANCED,
		quest_id,
		objective_id,
		{"quest_id": quest_id, "objective_id": objective_id, "current": current, "required": required}
	)


static func quest_completed(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_COMPLETED, quest_id, "", {"quest_id": quest_id})


static func quest_turned_in(quest_id: String) -> DomainEvent:
	return DomainEvent.create(QUEST_TURNED_IN, quest_id, "", {"quest_id": quest_id})
