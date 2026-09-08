extends RefCounted

var grid := AStarGrid2D.new()
var world: Node
const STEP := 20.0

func build(game: Node) -> void:
	world = game
	grid.region = Rect2i(-62,-44,125,89)
	grid.cell_size = Vector2.ONE*STEP
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(-44,45):
		for x in range(-62,63):
			grid.set_point_solid(Vector2i(x,y),not world.walkable(Vector2(x,y)*STEP,12))

func cell(at: Vector2) -> Vector2i:
	return Vector2i(roundi(at.x/STEP),roundi(at.y/STEP))

func clear_line(a: Vector2,b: Vector2) -> bool:
	var count := maxi(1,ceili(a.distance_to(b)/5))
	for i in range(count+1):
		if not world.walkable(a.lerp(b,float(i)/count),11): return false
	return true

func nearest(at: Vector2) -> Vector2i:
	var center := cell(at)
	var best := Vector2i(9999,9999)
	var distance := INF
	for y in range(-2,3):
		for x in range(-2,3):
			var c := center+Vector2i(x,y)
			if not grid.is_in_boundsv(c) or grid.is_point_solid(c): continue
			var d := at.distance_to(Vector2(c)*STEP)
			if d<distance and clear_line(at,Vector2(c)*STEP):
				best = c
				distance = d
	return best

func route(from: Vector2,to: Vector2) -> PackedVector2Array:
	if not world.walkable(to,11): return PackedVector2Array()
	var start := nearest(from)
	var finish := nearest(to)
	if start.x==9999 or finish.x==9999: return PackedVector2Array()
	var raw := grid.get_point_path(start,finish)
	if raw.is_empty(): return raw
	raw.append(to)
	# Keep exact destination and visibility-test all shortcuts using the same
	# collision query as movement, including tree trunks and water margins.
	var result := PackedVector2Array()
	var anchor := from
	var i := 0
	while i<raw.size():
		var farthest := i
		for j in range(i,raw.size()):
			if clear_line(anchor,raw[j]): farthest = j
			else: break
		result.append(raw[farthest])
		anchor = raw[farthest]
		i = farthest+1
	return result
