class_name PlayerAttackState
extends State

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

	var runner := ServiceRegistry.get_service("actions") as ActionService
	runner.start_action(action, ctx)


func exit(context: Dictionary = {}) -> void:
	if current_action != null and not current_action.is_finished():
		current_action.cancel("state_exit")
	current_action = null


func _on_action_completed(_action: GameAction) -> void:
	request_transition("Player/Idle", {"reason": "attack_finished"})
