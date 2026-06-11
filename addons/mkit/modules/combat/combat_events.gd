class_name CombatEvents
extends RefCounted
## 战斗领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。
## 通过 kernel 事件总线发布：`Mkit.events().emit_domain_event(CombatEvents.entity_died(...))`。

## 公开常量 `DAMAGE_APPLIED`，作为 `CombatEvents` 对外暴露的类型、事件或命令标识。
const DAMAGE_APPLIED := "damage_applied"
## 公开常量 `ENTITY_DIED`，作为 `CombatEvents` 对外暴露的类型、事件或命令标识。
const ENTITY_DIED := "entity_died"


## 执行 `damage_applied` 对应的公开操作，并保持 `CombatEvents` 的领域契约一致。
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


## 执行 `entity_died` 对应的公开操作，并保持 `CombatEvents` 的领域契约一致。
static func entity_died(entity_id: String, entity_ref: Node) -> DomainEvent:
	var payload: Dictionary = {"entity_id": entity_id, "entity_ref": entity_ref}
	if entity_ref != null:
		var identity := EntityContract.get_identity(entity_ref)
		if identity != null:
			payload["tags"] = identity.tags
			payload["faction"] = identity.faction
			payload["definition_id"] = identity.definition_id
	return DomainEvent.create(ENTITY_DIED, entity_id, "", payload)


## 执行 `entity_id_of` 对应的公开操作，并保持 `CombatEvents` 的领域契约一致。
static func entity_id_of(entity: Node) -> String:
	if entity == null:
		return ""
	var identity := EntityContract.get_identity(entity)
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
