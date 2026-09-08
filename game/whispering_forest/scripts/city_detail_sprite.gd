@tool
extends "res://game/whispering_forest/scripts/city_sprite.gd"

const Catalog = preload("res://game/whispering_forest/scripts/city_detail_catalog.gd")
var detail_key := ""
var tree := false
var wind_time := 0.0
var visible_width := 0.0
var calibrated_basis := Transform2D.IDENTITY

func refresh() -> void:
	detail_key = Catalog.key(asset,building_id,ground)
	if detail_key.is_empty():
		super.refresh()
		return
	position = WFIso.project(ground)
	if sprite==null:
		sprite=Sprite2D.new()
		sprite.name="Artwork"
		add_child(sprite)
	var entry: Dictionary = Catalog.FRAMES[detail_key]
	var r: Array = entry.region
	var region := Rect2(r[0],r[1],r[2],r[3])
	var pivot := Vector2(entry.pivot[0],entry.pivot[1])
	var drawing_basis := Catalog.basis(entry)
	var scale_value: float
	tree = not entry.has("base")
	if tree:
		scale_value = float(entry.height)*(0.94+posmod(roundi(ground.x+ground.y),5)*0.025)/region.size.y
	else:
		var base_bounds := Catalog.bounds(entry)
		scale_value = float(entry.display_width)/region.size.x
		pivot = drawing_basis.affine_inverse()*WFIso.project(base_bounds.end)
		footprint = base_bounds.size*scale_value
	sprite.texture=WFIso.atlas(load(Catalog.ROOT+detail_key+".png"),region)
	sprite.centered=false
	sprite.offset=-(pivot-region.position)
	calibrated_basis=drawing_basis.scaled(Vector2.ONE*scale_value)
	sprite.transform=calibrated_basis
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visible_width=region.size.x*scale_value
	signature=str([asset,ground,width])
	queue_redraw()

func _draw() -> void:
	if not tree: return
	var shadow := PackedVector2Array()
	for i in range(24):
		var a := TAU*i/24
		shadow.append(Vector2(22,12)+Vector2(cos(a)*visible_width*0.30,sin(a)*12))
	draw_colored_polygon(shadow,Color(0.13,0.22,0.20,0.20))
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
	draw_circle(Vector2.ZERO,11,Color(0.10,0.17,0.14,0.25))
	draw_set_transform(Vector2.ZERO)

func _process(delta: float) -> void:
	super._process(delta)
	if tree and sprite!=null and not Engine.is_editor_hint():
		wind_time+=delta
		sprite.transform=calibrated_basis.rotated_local(sin(wind_time*0.8+ground.x*0.01+ground.y*0.02)*0.002)
