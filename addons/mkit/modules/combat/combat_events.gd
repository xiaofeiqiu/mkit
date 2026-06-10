class_name CombatEvents
extends RefCounted
## Combat-owned domain event catalog: event type constants + DomainEvent constructors.
## Emit through the kernel bus: `Mkit.events().emit_domain_event(CombatEvents.entity_died(...))`.

const DAMAGE_APPLIED := "damage_applied"
const ENTITY_DIED := "entity_died"


static func damage_applied(result: DamageResult) -> DomainEvent:
	var data: Dictionary = {}
	var source_id := ""
	var target_id := ""
	if result != null:
		data = result.to_debug_dict()
		data["result"] = result
		source_id = entity_id_of(result.source)
		target_id = entity_id_of(result.target)
	return DomainEvent.create(DAMAGE_APPLIED, source_id, target_id, data)


static func entity_died(entity_id: String, entity_ref: Node) -> DomainEvent:
	var payload: Dictionary = {"entity_id": entity_id, "entity_ref": entity_ref}
	if entity_ref != null:
		var identity := EntityContract.get_identity(entity_ref)
		if identity != null:
			payload["tags"] = identity.tags
			payload["faction"] = identity.faction
			payload["definition_id"] = identity.definition_id
	return DomainEvent.create(ENTITY_DIED, entity_id, "", payload)


static func entity_id_of(entity: Node) -> String:
	if entity == null:
		return ""
	var identity := EntityContract.get_identity(entity)
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
