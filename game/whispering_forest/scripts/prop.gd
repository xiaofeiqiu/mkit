extends Node2D

var ground := Vector2.ZERO
var radius := 0.0
var sprite: Sprite2D
# Legacy setup argument is retained; environment occluders remain opaque.
var fadeable := false
var world: Node

func setup(texture: Texture2D, at: Vector2, width: float, collision_radius: float, game: Node, can_fade: bool = true) -> void:
	ground = at
	radius = collision_radius
	world = game
	fadeable = can_fade
	position = WFIso.project(at)
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var scale_factor := width / texture.get_width()
	sprite.scale = Vector2.ONE * scale_factor
	sprite.offset = Vector2(0, -texture.get_height() * 0.5 + 14)
	add_child(sprite)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(6, 0), -0.15, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, maxf(radius * 1.5, 18), Color(0.06, 0.13, 0.08, 0.2))
