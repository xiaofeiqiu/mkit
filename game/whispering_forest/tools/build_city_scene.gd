extends SceneTree

const Builder = preload("res://game/whispering_forest/scripts/city_builder.gd")
func _initialize() -> void:
	var city := Builder.create()
	var scene := PackedScene.new()
	var error := scene.pack(city)
	if error==OK: error = ResourceSaver.save(scene,"res://game/whispering_forest/city_layout.tscn")
	print("WF_CITY_SCENE: %d independent objects; save=%d" % [city.get_child_count(),error])
	city.free()
	quit(0 if error==OK else 1)
