## What: ApplyStatModifierEffect adds a runtime StatModifier to a StatsComponent.
## Responsibilities: build a modifier from exported values, choose source or target, and mark affected stats dirty.
## Upstream: abilities, equipment, consumables, upgrades, and status effects can trigger it.
## Downstream: StatsComponent recalculates values and notifies systems such as combat or movement.
## When to use: Use it for temporary buffs, debuffs, aura effects, or upgrades that alter numeric stats.
## Example: set `stat_id = "move_speed"`, `operation = PERCENT_ADD`, `value = 0.25`, `duration = 5.0` for a haste buff.
class_name ApplyStatModifierEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `stat_id`.
## Example: `self.stat_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stat_id: String = ""
## Purpose: Inspector-exposed configuration `operation`.
## Example: `self.operation = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
## Purpose: Inspector-exposed configuration `value`.
## Example: `self.value = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var value: float = 0.0
## Purpose: Inspector-exposed configuration `duration`.
## Example: `self.duration = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var duration: float = -1.0
## Purpose: Inspector-exposed configuration `stacking_rule`.
## Example: `self.stacking_rule = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
## Purpose: Inspector-exposed configuration `apply_to_source`.
## Example: `self.apply_to_source = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var apply_to_source: bool = true


func _apply_impl(context: GameplayContext) -> EffectResult:
	if stat_id == "":
		return EffectResult.fail(effect_id, "Missing stat_id")

	var receiver := context.source if apply_to_source else context.target
	if receiver == null:
		return EffectResult.fail(effect_id, "Missing receiver for stat modifier")

	var stats := receiver.get_node_or_null("Components/StatsComponent") as StatsComponent
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
