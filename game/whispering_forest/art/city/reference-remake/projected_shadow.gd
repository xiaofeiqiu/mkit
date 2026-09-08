extends RefCounted

# Orthographic projection of the actual triangles along the shared sun ray.
# Leaves and crenellation openings remain visible, unlike a single AABB hull.
static func build(source: Node3D,rotation: Vector3) -> Node3D:
	var shadow := Node3D.new()
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color.WHITE
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var ray := Basis.from_euler(rotation*PI/180.0)*Vector3.FORWARD
	collect(source,Transform3D.IDENTITY,ray,shadow,material)
	return shadow

static func collect(node: Node3D,parent: Transform3D,ray: Vector3,out: Node3D,material: Material) -> void:
	var transform := parent*node.transform
	if node is MeshInstance3D:
		var mesh := ArrayMesh.new()
		for surface in range(node.mesh.get_surface_count()):
			var original: Array=node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=original[Mesh.ARRAY_VERTEX]
			for i in range(vertices.size()):
				var p := transform*vertices[i]
				p+=ray*(-maxf(0.0,p.y)/ray.y)
				p.y=0.002
				vertices[i]=p
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_INDEX]=original[Mesh.ARRAY_INDEX]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var instance := MeshInstance3D.new()
		instance.mesh=mesh
		instance.material_override=material
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		out.add_child(instance)
	for child in node.get_children():
		if child is Node3D:collect(child,transform,ray,out,material)
