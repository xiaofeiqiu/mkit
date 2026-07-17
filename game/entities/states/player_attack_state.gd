class_name PlayerAttackState
extends HfsmState

const ATTACK_SFX_ID := "sfx.demo.attack"

var current_action: GameAction = null


func enter(context: Dictionary = {}) -> void:
	var body := owner_entity as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO

	# Swing the hitbox toward the way the player is facing.
	var facing: Vector2 = blackboard.get_value("facing", Vector2.RIGHT)
	var hitbox := owner_entity.get_node_or_null("Components/HitboxComponent") as HitboxComponent
	if hitbox != null:
		hitbox.position = facing.normalized() * 28.0
		_set_hitbox_indicator_visible(hitbox, true)

	_play_attack_sfx()

	var ctx := ActionContext.new()
	ctx.source = owner_entity
	ctx.direction = facing

	var action := TimedAttackAction.new()
	action.startup_duration = 0.05
	action.active_duration = 0.12
	action.recovery_duration = 0.10
	action.hitbox_path = NodePath("Components/HitboxComponent")
	action.completed.connect(_on_action_completed)
	current_action = action

	var runner := Mkit.actions()
	runner.start_action(action, ctx)


func exit(context: Dictionary = {}) -> void:
	if current_action != null and not current_action.is_finished():
		current_action.cancel("state_exit")
	current_action = null
	_hide_hitbox_indicator()


func _play_attack_sfx() -> void:
	var audio := Mkit.audio()
	if audio != null:
		audio.play_sfx(ATTACK_SFX_ID)


func _on_action_completed(_action: GameAction) -> void:
	_hide_hitbox_indicator()
	request_transition("Player/Idle", {"reason": "attack_finished"})


func _hide_hitbox_indicator() -> void:
	if owner_entity == null:
		return
	var hitbox := owner_entity.get_node_or_null("Components/HitboxComponent") as HitboxComponent
	if hitbox != null:
		_set_hitbox_indicator_visible(hitbox, false)


func _set_hitbox_indicator_visible(hitbox: HitboxComponent, visible: bool) -> void:
	var indicator := hitbox.get_node_or_null("DebugShape") as CanvasItem
	if indicator != null:
		indicator.visible = visible
