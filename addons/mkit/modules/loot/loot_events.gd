class_name LootEvents
extends RefCounted
## Loot-owned domain event catalog: event type constants + DomainEvent constructors.

const REWARD_SELECTED := "reward_selected"


static func reward_selected(reward_id: String, source_id: String = "") -> DomainEvent:
	return DomainEvent.create(REWARD_SELECTED, source_id, "", {"reward_id": reward_id})
