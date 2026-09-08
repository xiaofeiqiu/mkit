@tool
extends Node2D

@export var asset := "townhouse"
@export var ground := Vector2.ZERO
@export var world_scale := 1.0
@export var footprint := Vector2.ZERO
@export var radius := 0.0
@export var building_id := ""
@export var title_zh := ""
@export var title_en := ""
# Kept for scene/caller compatibility; occluders now remain opaque.
@export var fadeable := false
var world: Node
var sprite: Sprite2D
var signature := ""
var width := 0.0
const Art = preload("res://game/whispering_forest/scripts/city_art.gd")

func _ready() -> void:
	refresh()

func refresh() -> void:
	position = WFIso.project(ground)
	if sprite==null:
		sprite = Sprite2D.new()
		sprite.name = "Artwork"
		add_child(sprite)
	var texture: Texture2D = load(Art.ROOT+asset+".png")
	if texture==null: return
	var entry: Dictionary = Art.FRAMES[asset]
	var r: Array = entry.region
	var region := Rect2(r[0],r[1],r[2],r[3])
	var pivot := Vector2(entry.pivot[0],entry.pivot[1])-region.position
	footprint = Art.footprint(asset)*world_scale
	sprite.texture = WFIso.atlas(texture,region)
	sprite.centered = false
	sprite.offset = -pivot
	sprite.transform = Transform2D.IDENTITY.scaled(Vector2.ONE*float(entry.scale)*world_scale)
	width = region.size.x*float(entry.scale)*world_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	signature = str([asset,ground,world_scale])

func blocks(at: Vector2, actor_radius: float) -> bool:
	if footprint!=Vector2.ZERO and Rect2(ground-footprint,footprint).grow(actor_radius).has_point(at): return true
	return radius>0 and at.distance_to(ground)<radius+actor_radius

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if signature!=str([asset,ground,world_scale]): refresh()
