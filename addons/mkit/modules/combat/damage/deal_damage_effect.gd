class_name DealDamageEffect
extends GameEffect
## 说明：`DealDamageEffect` 是 伤害系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := DealDamageEffect.new()`

## 基础数值；在伤害或治疗结算中会被属性、倍率或规则进一步调整。
@export var base_amount: float = 10.0
## 伤害类型 id；用于抗性、格挡、事件标签或 UI 展示。
@export var damage_type: String = "physical"
## 元素类型 id；`none` 表示无元素，可用于弱点和抗性规则。
@export var element_type: String = "none"
## 本次伤害是否允许暴击；关闭后暴击率相关规则应跳过。
@export var can_crit: bool = true
## 随本次命中传递的标签；用于触发条件、状态和事件过滤。
@export var hit_tags: Array[String] = []
## 命中后尝试施加的状态配置列表；每项 Dictionary 应包含 status_id 等约定 key。
@export var on_hit_statuses: Array[Dictionary] = []


## 子类覆写的实际效果入口，并保持 `DealDamageEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var health := EntityContract.get_component(target, "HealthComponent") as HealthComponent
	if health == null:
		return EffectResult.fail(effect_id, "no_health_component")
	var request := DamageRequest.new()
	request.source = context.source
	request.target = target
	request.base_amount = base_amount
	request.damage_type = damage_type
	request.element_type = element_type
	request.can_crit = can_crit
	request.tags = hit_tags.duplicate()
	request.on_hit_statuses = on_hit_statuses.duplicate()
	var result := _resolve_combat(request)
	health.apply_damage(result)
	return EffectResult.ok(
		effect_id, {"final_amount": result.final_amount, "was_critical": result.was_critical}
	)


func _resolve_combat(request: DamageRequest) -> DamageResult:
	var resolver: CombatService = null
	resolver = Mkit.combat()
	if resolver == null:
		resolver = CombatService.new()
	return resolver.resolve(request)
