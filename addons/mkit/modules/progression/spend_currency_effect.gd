class_name SpendCurrencyEffect
extends GameEffect
## 说明：`SpendCurrencyEffect` 是 成长系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := SpendCurrencyEffect.new()`


## 运行时状态：`currency_id` 表示稳定 id，由 `SpendCurrencyEffect` 的公开 API 读取或维护。
var currency_id: String = ""
## 运行时状态：`amount` 表示数量值，由 `SpendCurrencyEffect` 的公开 API 读取或维护。
var amount: int = 0


## 检查当前上下文是否允许 `spend`，并保持 `SpendCurrencyEffect` 的领域契约一致。
static func can_spend(check_currency_id: String, check_amount: int) -> bool:
	var progression := Mkit.progression()
	if progression == null:
		return false
	return progression.get_currency(check_currency_id) >= check_amount


## 子类覆写的实际效果入口，并保持 `SpendCurrencyEffect` 的领域契约一致。
func _apply_impl(_context: GameplayContext) -> EffectResult:
	var progression := Mkit.progression()
	if progression == null:
		return EffectResult.fail(effect_id, "Missing progression service")
	if not progression.spend_currency(currency_id, amount):
		return EffectResult.fail(effect_id, "Insufficient currency")
	return EffectResult.ok(effect_id)
