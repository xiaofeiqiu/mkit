class_name StatModifier
extends RefCounted
var modifier_id: String = ""
var stat_id: String = ""
var source_id: String = ""
var operation: StatModifierDefinition.Operation
var value: float = 0.0
var priority: int = 0
var stacking_rule: StatModifierDefinition.StackingRule
var remaining_duration: float = -1.0
var tags: Array[String] = []


static func from_definition(
	definition: StatModifierDefinition, source: String, duration: float = -1.0
) -> StatModifier:
	var m := StatModifier.new()
	m.modifier_id = definition.modifier_id
	m.stat_id = definition.stat_id
	m.source_id = source
	m.operation = definition.operation
	m.value = definition.value
	m.priority = definition.priority
	m.stacking_rule = definition.stacking_rule
	m.remaining_duration = duration
	m.tags = definition.tags.duplicate()
	return m


func to_save_data() -> Dictionary:
	return {
		"modifier_id": modifier_id,
		"stat_id": stat_id,
		"source_id": source_id,
		"operation": int(operation),
		"value": value,
		"priority": priority,
		"stacking_rule": int(stacking_rule),
		"remaining_duration": remaining_duration,
		"tags": tags.duplicate()
	}


static func from_save_data(data: Dictionary) -> StatModifier:
	var m := StatModifier.new()
	m.modifier_id = str(data.get("modifier_id", ""))
	m.stat_id = str(data.get("stat_id", ""))
	m.source_id = str(data.get("source_id", ""))
	m.operation = data.get("operation", StatModifierDefinition.Operation.FLAT_ADD)
	m.value = float(data.get("value", 0.0))
	m.priority = int(data.get("priority", 0))
	m.stacking_rule = data.get("stacking_rule", StatModifierDefinition.StackingRule.STACK)
	m.remaining_duration = float(data.get("remaining_duration", -1.0))
	m.tags = []
	for tag in data.get("tags", []):
		m.tags.append(str(tag))
	return m
