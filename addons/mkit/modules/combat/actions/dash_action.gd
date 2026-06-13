class_name DashAction
extends GameAction
## 说明：`DashAction` 是 动作管线 的动作对象，负责封装可启动、更新、取消或完成的 gameplay 行为。
## 上游：通常由 ActionService、状态机、能力控制器或脚本创建或调用。
## 下游：会连接EffectService、GameEffect、ActionContext 和完成/取消信号，不直接依赖具体游戏内容。
## 使用：当项目行为需要跨帧执行、可取消，或在开始/完成时触发效果时使用它。
## 示例：`var instance := DashAction.new()`

## 持续时间，单位为秒；0 通常表示立即完成，负数是否有效由具体子类约定。
var duration: float = 0.18
## 移动速度，单位为像素/秒。
var speed: float = 480.0
## 本次行为的朝向或移动方向；调用方应按需要传入归一化向量。
var direction: Vector2 = Vector2.ZERO


## GameAction 启动 hook；ActionService 调用后子类可初始化移动、计时或效果状态。
func _on_start() -> void:
	action_id = "dash"
	cancel_tags = ["stun", "death"]
	direction = context.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT


## GameAction 更新 hook；ActionService 每帧传入 delta，子类可推进计时或移动。
func _on_update(delta: float) -> void:
	if context.source == null:
		complete()
		return
	var body := context.source as CharacterBody2D
	if body != null:
		body.velocity = direction * speed
		body.move_and_slide()
	if elapsed >= duration:
		complete()


## GameAction 完成 hook；流程成功结束时调用，子类可提交最终效果或清理状态。
func _on_complete() -> void:
	var body := context.source as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO
