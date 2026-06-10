class_name AddCurrencyEffect
extends GameEffect

var currency_id: String = ""
var amount: int = 0


func _apply_impl(_context: GameplayContext) -> EffectResult:
	var progression := Mkit.progression()
	if progression != null:
		progression.add_currency(currency_id, amount)
	return EffectResult.ok(effect_id)
