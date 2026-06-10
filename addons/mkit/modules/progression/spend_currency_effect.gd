class_name SpendCurrencyEffect
extends GameEffect

var currency_id: String = ""
var amount: int = 0


static func can_spend(check_currency_id: String, check_amount: int) -> bool:
	var progression := Mkit.progression()
	if progression == null:
		return false
	return progression.get_currency(check_currency_id) >= check_amount


func _apply_impl(_context: GameplayContext) -> EffectResult:
	var progression := Mkit.progression()
	if progression == null:
		return EffectResult.fail(effect_id, "Missing progression service")
	if not progression.spend_currency(currency_id, amount):
		return EffectResult.fail(effect_id, "Insufficient currency")
	return EffectResult.ok(effect_id)
