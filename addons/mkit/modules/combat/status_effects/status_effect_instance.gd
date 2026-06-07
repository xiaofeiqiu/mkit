class_name StatusEffectInstance
extends RefCounted
var instance_id: String = ""
var definition_id: String = ""
var source_id: String = ""
var source: Node = null
var target: Node = null
var remaining_duration: float = 0.0
var tick_timer: float = 0.0
var stacks: int = 1
var applied_modifier_ids: Array[String] = []


func setup(
	definition: StatusEffectDefinition,
	source_entity: Node,
	target_entity: Node,
	initial_stacks: int,
	duration_override: float = -1.0
) -> void:
	instance_id = "%s_%d" % [definition.status_id, Time.get_ticks_usec()]
	definition_id = definition.status_id
	source_id = ""
	source = source_entity
	target = target_entity
	stacks = initial_stacks
	remaining_duration = duration_override if duration_override > 0 else definition.duration
	tick_timer = definition.tick_interval
