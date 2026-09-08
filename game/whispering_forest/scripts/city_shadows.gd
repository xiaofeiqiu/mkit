@tool
extends Node2D

const Art = preload("res://game/whispering_forest/scripts/city_art.gd")
var silhouettes: Array[PackedVector2Array] = []
var world: Node
var projected_sprites: Array[Sprite2D] = []

func _ready() -> void:
	rebuild.call_deferred()

func rebuild() -> void:
	silhouettes.clear()
	for sprite in projected_sprites:sprite.queue_free()
	projected_sprites.clear()
	var material := ShaderMaterial.new()
	material.shader=load("res://game/whispering_forest/art/city/reference-remake/soft_ground_shadow.gdshader")
	for prop in get_parent().get_children():
		var id = prop.get("asset")
		if not id is String or not Art.FRAMES.has(id): continue
		var data: Dictionary = Art.FRAMES[id]
		if data.has("shadow_texture"):
			var sprite := Sprite2D.new()
			sprite.texture=load(Art.ROOT+data.shadow_texture)
			sprite.centered=false
			sprite.offset=-Vector2(data.shadow_pivot[0],data.shadow_pivot[1])
			sprite.scale=Vector2.ONE*data.scale
			sprite.position=WFIso.project(prop.ground)
			sprite.modulate=Color(0.19,0.27,0.32,0.23)
			sprite.material=material
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			add_child(sprite)
			projected_sprites.append(sprite)
			continue
		if not data.has("shadow_outline") or data.shadow_outline.size()<3: continue
		var at: Vector2 = prop.ground
		var points := PackedVector2Array()
		for p in data.shadow_outline: points.append(WFIso.project(at+Vector2(p[0],p[1])))
		silhouettes.append(points)
	queue_redraw()

func _draw() -> void:
	for poly in silhouettes: draw_colored_polygon(poly,Color(0.18,0.28,0.29,0.15))
