class_name AddCurrencyEffect
extends GameEffect

var currency_id: String = ""
var amount: int = 0


func _apply_impl(_context: GameplayContext) -> EffectResult:
	if ServiceRegistry.has_service("progression"):
		var progression := ServiceRegistry.get_service("progression") as ProgressionService
		progression.add_currency(currency_id, amount)
	return EffectResult.ok(effect_id)
