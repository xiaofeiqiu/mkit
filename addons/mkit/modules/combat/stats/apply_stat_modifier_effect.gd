class_name ApplyStatModifierEffect
extends GameEffect
@export var stat_id: String = ""
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
@export var value: float = 0.0
@export var duration: float = -1.0
@export
var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
@export var apply_to_source: bool = true


func _apply_impl(context: GameplayContext) -> EffectResult:
	if stat_id == "":
		return EffectResult.fail(effect_id, "Missing stat_id")
	var receiver := context.source if apply_to_source else context.target
	if receiver == null:
		return EffectResult.fail(effect_id, "Missing receiver for stat modifier")
	var stats := EntityContract.get_component(receiver, "StatsComponent") as StatsComponent
	if stats == null:
		return EffectResult.fail(effect_id, "Receiver has no StatsComponent")
	var mod_def := StatModifierDefinition.new()
	mod_def.modifier_id = effect_id if effect_id != "" else "mod.%s" % stat_id
	mod_def.stat_id = stat_id
	mod_def.operation = operation
	mod_def.value = value
	mod_def.stacking_rule = stacking_rule
	var modifier := StatModifier.from_definition(mod_def, mod_def.modifier_id, duration)
	stats.add_modifier(modifier)
	return EffectResult.ok(effect_id, {"stat_id": stat_id, "value": value, "duration": duration})
