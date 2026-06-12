class_name CompleteQuestEffect
extends GameEffect
## 说明：`CompleteQuestEffect` 是 任务系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := CompleteQuestEffect.new()`

## 引用的 QuestDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var quest_id: String = ""
## 完成任务时是否同时进入交付状态；关闭后仅标记目标完成。
@export var turn_in: bool = true


## 子类覆写的实际效果入口，并保持 `CompleteQuestEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	if quest_id == "":
		return EffectResult.fail(effect_id, "Missing quest_id")
	var quest := Mkit.quest()
	if quest == null:
		return EffectResult.fail(effect_id, "Missing quest service")
	var succeeded := false
	if turn_in:
		var state := quest.get_state(quest_id)
		if state != null and state.status == QuestState.STATUS_COMPLETED:
			succeeded = quest.turn_in_quest(quest_id, context)
		else:
			succeeded = quest.complete_quest(quest_id, context)
			state = quest.get_state(quest_id)
			if succeeded and state != null and state.status == QuestState.STATUS_COMPLETED:
				succeeded = quest.turn_in_quest(quest_id, context)
	else:
		succeeded = quest.complete_quest(quest_id, context)
	if not succeeded:
		return EffectResult.fail(effect_id, "Quest transition failed: %s" % quest_id)
	return EffectResult.ok(effect_id, {"quest_id": quest_id, "turn_in": turn_in})
