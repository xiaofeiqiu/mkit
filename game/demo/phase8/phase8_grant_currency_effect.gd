class_name Phase8GrantCurrencyEffect
extends GameEffect

@export var currency_id: String = "gold"
@export var amount: int = 0


func _apply_impl(_context: GameplayContext) -> EffectResult:
	if currency_id.strip_edges() == "":
		return EffectResult.fail(effect_id, "Missing currency_id")
	if amount <= 0:
		return EffectResult.fail(effect_id, "Invalid amount")
	if not ServiceRegistry.has_service("progression"):
		return EffectResult.fail(effect_id, "Missing progression service")
	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	if progression == null:
		return EffectResult.fail(effect_id, "Missing progression service")
	progression.add_currency(currency_id, amount)
	return EffectResult.ok(effect_id, {"currency_id": currency_id, "amount": amount})
