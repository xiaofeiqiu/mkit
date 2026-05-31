## What: SpawnSceneEffect is a content effect that instantiates a scene during effect execution.
## Responsibilities: load a PackedScene path, choose a spawn parent/position, add the instance, and return spawn metadata.
## Upstream: abilities, rewards, room scripts, or items trigger it through EffectExecutor.
## Downstream: the spawned scene enters the active tree and can continue with its own scripts/components.
## When to use: Use it for traps, summoned allies, projectiles, VFX, or interactables created by data-driven content.
## Example: set `scene_path = "res://game/fx/explosion.tscn"` and `spawn_at_target = true` in an ability effect.
class_name SpawnSceneEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `scene_path`.
## Example: `self.scene_path = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var scene_path: String = ""
## Purpose: Inspector-exposed configuration `spawn_at_target`.
## Example: `self.spawn_at_target = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var spawn_at_target: bool = false


func _apply_impl(context: GameplayContext) -> EffectResult:
	if scene_path == "":
		return EffectResult.fail(effect_id, "missing_scene_path")
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return EffectResult.fail(effect_id, "cannot_load_scene")

	var instance := packed.instantiate()

	var spawn_pos := context.position
	if spawn_at_target and context.target != null and context.target is Node2D:
		spawn_pos = (context.target as Node2D).global_position
	elif context.source != null and context.source is Node2D:
		spawn_pos = (context.source as Node2D).global_position

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return EffectResult.fail(effect_id, "no_scene_tree")
	tree.current_scene.add_child(instance)

	if instance is Node2D:
		(instance as Node2D).global_position = spawn_pos
		if context.direction != Vector2.ZERO and instance.has_method("set_direction"):
			instance.call("set_direction", context.direction)

	return EffectResult.ok(effect_id, {"spawned": instance.name})
