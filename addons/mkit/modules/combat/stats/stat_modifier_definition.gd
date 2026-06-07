class_name StatModifierDefinition
extends Resource
enum Operation { FLAT_ADD, PERCENT_ADD, PERCENT_MULTIPLY, OVERRIDE, CLAMP_MIN, CLAMP_MAX }
enum StackingRule { STACK, REPLACE_SAME_SOURCE, HIGHEST_ONLY, LOWEST_ONLY, UNIQUE }
@export var modifier_id: String = ""
@export var stat_id: String = ""
@export var operation: Operation = Operation.FLAT_ADD
@export var value: float = 0.0
@export var priority: int = 0
@export var stacking_rule: StackingRule = StackingRule.STACK
@export var tags: Array[String] = []
