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


static func from_definition(definition: StatModifierDefinition, source: String, duration: float = -1.0) -> StatModifier:
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
