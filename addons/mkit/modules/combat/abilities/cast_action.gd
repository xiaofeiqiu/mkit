class_name CastAction
extends GameAction
## 说明：`CastAction` 是 能力系统 的动作对象，负责封装可启动、更新、取消或完成的 gameplay 行为。
## 上游：通常由 ActionService、状态机、能力控制器或脚本创建或调用。
## 下游：会连接EffectService、GameEffect、ActionContext 和完成/取消信号，不直接依赖具体游戏内容。
## 使用：当项目行为需要跨帧执行、可取消，或在开始/完成时触发效果时使用它。
## 示例：`var instance := CastAction.new()`

## 施放动作持续时间，单位为秒；到时后触发能力效果。
var duration: float = 0.0
## 施放或动作播放的动画名称；目标 AnimationPlayer 不存在该动画时应安全跳过。
var animation_name: String = "cast"
var _started_animation: bool = false


## GameAction 启动 hook；ActionService 调用后子类可初始化移动、计时或效果状态。
func _on_start() -> void:
	action_id = "cast"
	cancel_tags = ["stun", "death", "silence"]
	context.duration = duration
	_play_animation()


## GameAction 更新 hook；ActionService 每帧传入 delta，子类可推进计时或移动。
func _on_update(delta: float) -> void:
	if context == null or context.source == null:
		cancel("missing_source")
		return
	if elapsed >= duration:
		complete()


## GameAction 取消 hook；流程中断时接收 reason，子类可清理临时状态。
func _on_cancel(reason: String) -> void:
	_stop_cast_feedback()


## GameAction 完成 hook；流程成功结束时调用，子类可提交最终效果或清理状态。
func _on_complete() -> void:
	_stop_cast_feedback()


func _play_animation() -> void:
	if _started_animation or context == null or context.source == null:
		return
	var anim := EntityContract.get_contract_node(context.source, "Presentation", "AnimationPlayer") as AnimationPlayer
	if anim != null and animation_name != "":
		anim.play(animation_name)
	_started_animation = true


func _stop_cast_feedback() -> void:
	if context == null or context.source == null:
		return
	if context.source.has_method("on_cast_action_finished"):
		context.source.call("on_cast_action_finished", self)
