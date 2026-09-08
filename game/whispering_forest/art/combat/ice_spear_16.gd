extends Node3D

# One full-sized spear is translated up through the ground plane. Its mesh,
# cross-section and facet layout never inflate or contract between poses.
const HEIGHT := 3.1
const Motion = preload("res://game/whispering_forest/art/combat/ice_motion.gd")
const TIMES := Motion.TIMES
const REVEAL := [0.0,0.0,0.0,0.0,0.0,0.0,0.10,0.80,2.00,3.10,3.10,3.10,3.10,3.10,3.10,3.10]
var spear: MeshInstance3D

func build() -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	for row in range(4):
		var ring:=PackedVector3Array()
		for side in range(6):
			var a: float=side*TAU/6+0.12
			var r: float=[0.49,0.40,0.21,0.001][row]
			ring.append(Vector3(cos(a)*r+0.06*row/3.0,[0.0,0.90,2.13,HEIGHT][row],sin(a)*r*0.76))
		rings.append(ring)
	for row in range(3):
		for side in range(6):
			var next: int=(side+1)%6
			var color: Color=[Color("f4f5f4"),Color("c7d2d8"),Color("e4e9eb"),Color("ffffff"),Color("f4f7f8"),Color("d6dfe3")][side]
			tri(st,rings[row][side],rings[row+1][side],rings[row][next],color)
			tri(st,rings[row][next],rings[row+1][side],rings[row+1][next],color.lightened(0.07))
	spear=MeshInstance3D.new()
	spear.name="FullSizedIceSpear"
	spear.mesh=st.commit()
	var mat:=ShaderMaterial.new()
	mat.shader=load("res://game/whispering_forest/art/combat/ice_emerge.gdshader")
	spear.material_override=mat
	add_child(spear)

func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	st.set_normal((b-a).cross(c-a).normalized())
	for p in [a,b,c]: st.add_vertex(p)

func pose(frame: int) -> void:
	spear.visible=REVEAL[frame]>0
	spear.position.y=REVEAL[frame]-HEIGHT
