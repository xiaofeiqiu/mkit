extends ModuleBootstrap

func _build_services() -> Dictionary:
	var services := super()
	services[CombatService.SERVICE_ID] = preload("res://game/whispering_forest/scripts/combat.gd").new()
	return services

# The sample owns a separate profile, loaded after its scene is constructed.
func _load_profile() -> void:
	pass
