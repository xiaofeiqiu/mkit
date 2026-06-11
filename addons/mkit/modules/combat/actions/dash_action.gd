class_name DashAction
extends GameAction
## 说明：`DashAction` 是 动作管线 的动作对象，负责封装可启动、更新、取消或完成的 gameplay 行为。
## 上游：通常由 ActionService、状态机、能力控制器或脚本创建或调用。
## 下游：会连接EffectService、GameEffect、ActionContext 和完成/取消信号，不直接依赖具体游戏内容。
## 使用：当项目行为需要跨帧执行、可取消，或在开始/完成时触发效果时使用它。
## 示例：`var instance := DashAction.new()`

## 运行时状态：`duration` 表示持续时间，由 `DashAction` 的公开 API 读取或维护。
var duration: float = 0.18
## 运行时状态：`speed` 表示 `DashAction` 的字段值，由 `DashAction` 的公开 API 读取或维护。
var speed: float = 480.0
## 运行时状态：`direction` 表示 `DashAction` 的字段值，由 `DashAction` 的公开 API 读取或维护。
var direction: Vector2 = Vector2.ZERO


## 动作启动时的覆写 hook，并保持 `DashAction` 的领域契约一致。
func _on_start() -> void:
	action_id = "dash"
	cancel_tags = ["stun", "death"]
	direction = context.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT


## 动作更新时的覆写 hook，并保持 `DashAction` 的领域契约一致。
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


## 动作完成时的覆写 hook，并保持 `DashAction` 的领域契约一致。
func _on_complete() -> void:
	var body := context.source as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO
