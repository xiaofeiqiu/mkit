class_name CombatEvents
extends RefCounted
## 战斗领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。
## 通过 kernel 事件总线发布：`Mkit.events().emit_domain_event(CombatEvents.entity_died(...))`。

## 稳定标识 `DAMAGE_APPLIED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const DAMAGE_APPLIED := "damage_applied"
## 稳定标识 `ENTITY_DIED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ENTITY_DIED := "entity_died"


## 执行 `damage_applied` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
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


## 执行 `entity_died` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func entity_died(entity_id: String, entity_ref: Node, killer_ref: Node = null) -> DomainEvent:
	var payload: Dictionary = {
		"entity_id": entity_id,
		"entity_ref": entity_ref,
		"killer_id": entity_id_of(killer_ref),
		"killer_ref": killer_ref,
	}
	if entity_ref != null:
		var identity := EntityContract.get_identity(entity_ref)
		if identity != null:
			payload["tags"] = identity.tags
			payload["faction"] = identity.faction
			payload["definition_id"] = identity.definition_id
	if killer_ref != null:
		var killer_identity := EntityContract.get_identity(killer_ref)
		if killer_identity != null:
			payload["killer_tags"] = killer_identity.tags
			payload["killer_faction"] = killer_identity.faction
			payload["killer_definition_id"] = killer_identity.definition_id
	return DomainEvent.create(ENTITY_DIED, entity_id, "", payload)


## 执行 `entity_id_of` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func entity_id_of(entity: Node) -> String:
	if entity == null:
		return ""
	var identity := EntityContract.get_identity(entity)
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
