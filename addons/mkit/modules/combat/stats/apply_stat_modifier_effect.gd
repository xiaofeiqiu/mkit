class_name ApplyStatModifierEffect
extends GameEffect
## 说明：`ApplyStatModifierEffect` 是 属性系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := ApplyStatModifierEffect.new()`

## 编辑器配置：`stat_id` 表示稳定 id，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
@export var stat_id: String = ""
## 编辑器配置：`operation` 表示 `ApplyStatModifierEffect` 的字段值，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
@export var operation: StatModifierDefinition.Operation = StatModifierDefinition.Operation.FLAT_ADD
## 编辑器配置：`value` 表示 `ApplyStatModifierEffect` 的字段值，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
@export var value: float = 0.0
## 编辑器配置：`duration` 表示持续时间，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
@export var duration: float = -1.0
## 编辑器配置：`stacking_rule` 表示 `ApplyStatModifierEffect` 的字段值，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
@export
var stacking_rule: StatModifierDefinition.StackingRule = StatModifierDefinition.StackingRule.STACK
## 编辑器配置：`apply_to_source` 表示 `ApplyStatModifierEffect` 的字段值，由 `ApplyStatModifierEffect` 的公开 API 读取或维护。
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
