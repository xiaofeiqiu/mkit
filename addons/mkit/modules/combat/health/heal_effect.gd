class_name HealEffect
extends GameEffect
## 说明：`HealEffect` 是 生命与资源系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := HealEffect.new()`

## 基础数值；在伤害或治疗结算中会被属性、倍率或规则进一步调整。
@export var base_amount: float = 20.0


## GameEffect 子类实现此 hook 完成实际效果；apply() 会调用它并返回 EffectResult。
func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target if context.target != null else context.source
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var health := EntityContract.get_component(target, "HealthComponent") as HealthComponent
	if health == null:
		return EffectResult.fail(effect_id, "no_health_component")
	health.heal(base_amount, context.source)
	return EffectResult.ok(effect_id, {"healed_amount": base_amount})
