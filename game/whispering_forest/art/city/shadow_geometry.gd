extends RefCounted

const Config = preload("res://game/whispering_forest/art/city/render_config.gd")

static func outline(model: Node3D,anchor: Vector3) -> Array:
	var rotation: Vector3 = Config.DATA.key_rotation*PI/180.0
	var ray := Basis.from_euler(rotation)*Vector3.FORWARD
	var points := PackedVector2Array()
	collect(model,Transform3D.IDENTITY,ray,anchor,points)
	var result := []
	if points.size()<3: return result
	for p in Geometry2D.convex_hull(points): result.append([snappedf(p.x,0.001),snappedf(p.y,0.001)])
	return result

static func collect(node: Node3D,parent_transform: Transform3D,ray: Vector3,anchor: Vector3,points: PackedVector2Array) -> void:
	var transform := parent_transform*node.transform
	if node is MeshInstance3D and node.mesh!=null:
		var bounds: AABB = node.mesh.get_aabb()
		for i in range(8):
			var p := transform*bounds.get_endpoint(i)
			p+=ray*(-maxf(0,p.y)/ray.y)
			p=(p-anchor)*Config.DATA.logical_units_per_metre
			points.append(Vector2(p.x,p.z))
	for child in node.get_children():
		if child is Node3D: collect(child,transform,ray,anchor,points)
