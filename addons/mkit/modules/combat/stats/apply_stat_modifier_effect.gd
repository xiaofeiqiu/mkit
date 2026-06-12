class_name ApplyStatModifierEffect
extends GameEffect
## 说明：`ApplyStatModifierEffect` 是 属性系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := ApplyStatModifierEffect.new()`

## 引用的 StatDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var stat_id: String = ""
## 属性修饰运算类型；决定 value 是加法、倍率还是覆盖等规则。
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
## 属性或修饰器数值；具体含义由 operation 或所在定义决定。
@export var value: float = 0.0
## 持续时间，单位为秒；0 通常表示立即完成，负数是否有效由具体子类约定。
@export var duration: float = -1.0
## 同源或同类修饰叠加规则；决定重复应用时覆盖、刷新还是累加。
@export
var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
## 是否把属性修饰施加到上下文 source；关闭时施加到 target。
@export var apply_to_source: bool = true


## 子类覆写的实际效果入口，并保持 `ApplyStatModifierEffect` 的领域契约一致。
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
