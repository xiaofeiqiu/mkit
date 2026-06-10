class_name Portal
extends Interactable
@export var target_zone_id: String = ""
@export var target_spawn_id: String = "default"


func _interact_impl(_context: GameplayContext) -> bool:
	if target_zone_id == "":
		return false
	if not ServiceRegistry.has_service(ServiceRegistry.SERVICE_WORLD):
		return false
	var world := Mkit.world()
	if world == null:
		return false
	return world.go_to_zone(target_zone_id, target_spawn_id)
