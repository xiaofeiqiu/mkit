class_name AcceptQuestEffect
extends GameEffect
## 说明：`AcceptQuestEffect` 是 任务系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := AcceptQuestEffect.new()`

## 编辑器配置：`quest_id` 表示稳定 id，由 `AcceptQuestEffect` 的公开 API 读取或维护。
@export var quest_id: String = ""


## 子类覆写的实际效果入口，并保持 `AcceptQuestEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	if quest_id == "":
		return EffectResult.fail(effect_id, "Missing quest_id")
	var quest := Mkit.quest()
	if quest == null:
		return EffectResult.fail(effect_id, "Missing quest service")
	if not quest.accept_quest(quest_id, context):
		return EffectResult.fail(effect_id, "Cannot accept quest: %s" % quest_id)
	return EffectResult.ok(effect_id, {"quest_id": quest_id})
