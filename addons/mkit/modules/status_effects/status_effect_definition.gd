class_name StatusEffectDefinition
extends ContentDefinition
enum StackRule { REFRESH_DURATION, ADD_STACK, REPLACE, IGNORE, EXTEND_DURATION, INDEPENDENT_STACKS }
@export var status_id: String = ""
@export var display_name: String = ""
@export var duration: float = 5.0
@export var tick_interval: float = 1.0
@export var max_stacks: int = 1
@export var stack_rule: StackRule = StackRule.REFRESH_DURATION
@export var tags: Array[String] = []
@export var effects_on_apply: Array[GameEffect] = []
@export var effects_on_tick: Array[GameEffect] = []
@export var effects_on_remove: Array[GameEffect] = []
@export var stat_modifiers: Array[StatModifierDefinition] = []


func get_content_id() -> String:
	return status_id
