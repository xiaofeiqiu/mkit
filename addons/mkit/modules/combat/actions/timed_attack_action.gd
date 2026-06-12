class_name TimedAttackAction
extends GameAction
## 说明：`TimedAttackAction` 是 动作管线 的动作对象，负责封装可启动、更新、取消或完成的 gameplay 行为。
## 上游：通常由 ActionService、状态机、能力控制器或脚本创建或调用。
## 下游：会连接EffectService、GameEffect、ActionContext 和完成/取消信号，不直接依赖具体游戏内容。
## 使用：当项目行为需要跨帧执行、可取消，或在开始/完成时触发效果时使用它。
## 示例：`var instance := TimedAttackAction.new()`

## 攻击启动前摇秒数；期间通常不启用 hitbox。
var startup_duration: float = 0.12
## 攻击判定保持启用的秒数。
var active_duration: float = 0.10
## 攻击收招秒数；结束后动作才算完成。
var recovery_duration: float = 0.25
## 默认查找的 HitboxComponent 节点名；hitbox_path 为空时使用。
var hitbox_component_name: StringName = &"HitboxComponent"
## 显式指定的 HitboxComponent NodePath；为空时按 hitbox_component_name 查找。
var hitbox_path: NodePath = NodePath("")
var _hitbox_enabled: bool = false


## 动作启动时的覆写 hook，并保持 `TimedAttackAction` 的领域契约一致。
func _on_start() -> void:
	action_id = "timed_attack"
	cancel_tags = ["dash", "stun", "death"]
	_play_animation("attack")
	_set_hitbox_enabled(false)


## 动作更新时的覆写 hook，并保持 `TimedAttackAction` 的领域契约一致。
func _on_update(delta: float) -> void:
	var total_active_start := startup_duration
	var total_active_end := startup_duration + active_duration
	var total_end := startup_duration + active_duration + recovery_duration
	if elapsed >= total_active_start and elapsed < total_active_end:
		if not _hitbox_enabled:
			_set_hitbox_enabled(true)
	else:
		if _hitbox_enabled:
			_set_hitbox_enabled(false)
	if elapsed >= total_end:
		complete()


## 动作取消时的覆写 hook，并保持 `TimedAttackAction` 的领域契约一致。
func _on_cancel(reason: String) -> void:
	_set_hitbox_enabled(false)


## 动作完成时的覆写 hook，并保持 `TimedAttackAction` 的领域契约一致。
func _on_complete() -> void:
	_set_hitbox_enabled(false)


func _set_hitbox_enabled(enabled: bool) -> void:
	_hitbox_enabled = enabled
	if context == null or context.source == null:
		return
	var hitbox: HitboxComponent = null
	if hitbox_path != NodePath(""):
		var hitbox_node := context.source.get_node_or_null(hitbox_path) as Node
		hitbox = hitbox_node as HitboxComponent
	if hitbox == null:
		hitbox = EntityContract.get_component(context.source, hitbox_component_name) as HitboxComponent
	if hitbox != null:
		hitbox.set_active(enabled)


func _play_animation(anim_name: String) -> void:
	if context == null or context.source == null:
		return
	var anim := EntityContract.get_contract_node(context.source, "Presentation", "AnimationPlayer") as AnimationPlayer
	if anim != null and anim.has_animation(anim_name):
		anim.play(anim_name)
