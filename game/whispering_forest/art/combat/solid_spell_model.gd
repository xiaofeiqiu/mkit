extends Node3D

# Editable volume sources. The root is the spell's exact ground/stone centre;
# all poses are rendered through the city's locked camera and daylight stage.
const FRAMES := 8
const ICE_TIMES := [0.0,0.20,0.45,0.72,1.15,1.62,1.95,2.30]
const ICE_HEIGHTS := [0.0,0.0,0.55,1.65,3.40,2.85,2.22,2.16]
const ICE_WIDTHS := [0.0,0.0,0.47,0.59,0.65,0.67,0.65,0.64]
var stone: MeshInstance3D

func surface(emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo=true
	mat.vertex_color_is_srgb=true
	mat.roughness=0.97
	mat.metallic_specular=0.02
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled=emission>0
	mat.emission=Color("dbefff")
	mat.emission_energy_multiplier=emission
	return mat

func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	var normal: Vector3=(b-a).cross(c-a).normalized()
	for point in [a,b,c]:
		st.set_normal(normal)
		st.add_vertex(point)

func finish(st: SurfaceTool, mat: Material, label: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name=label
	mesh.mesh=st.commit()
	mesh.material_override=mat
	add_child(mesh)
	return mesh

func clear_pose() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func ice_pose(frame: int) -> void:
	clear_pose()
	name="IcePillar_FixedGroundRoot"
	var height: float=ICE_HEIGHTS[frame]
	if frame<6: seal([0.24,0.83,0.85,0.90,0.93,0.76][frame])
	if height<=0: return
	var width: float=ICE_WIDTHS[frame]
	var glow: float=[0.0,0.0,0.75,0.85,0.90,0.40,0.26,0.24][frame]
	ice_mass(Vector3.ZERO,width,height,0.0,glow)
	# Two attached shoulders rise with the same glacier, then fold back into it.
	var shoulder: float=[0.0,0.0,0.0,0.30,0.82,0.60,0.30,0.28][frame]
	if shoulder>0:
		ice_mass(Vector3(-width*0.53,0,width*0.18),width*0.43,height*shoulder,-0.09,glow)
		ice_mass(Vector3(width*0.42,0,-width*0.29),width*0.37,height*(shoulder+0.10),0.12,glow)

func seal(radius: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in range(24):
		var angle: float=i*TAU/24.0
		var reach: float=radius*(1.0+0.08*sin(i*2.7) if i%2==0 else 0.65)
		points.append(Vector3(cos(angle)*reach,0.012,sin(angle)*reach))
	for i in range(points.size()): triangle(st,Vector3(0,0.012,0),points[i],points[(i+1)%points.size()],Color.WHITE)
	var mat := surface()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	finish(st,mat,"WhiteJaggedGroundSeal")

func ice_mass(at: Vector3, width: float, height: float, lean: float, emission: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array]=[]
	var levels := [0.0,0.24,0.49,0.74,1.0]
	var radii := [0.90,1.0,0.70,0.38,0.015]
	for row in range(5):
		var ring:=PackedVector3Array()
		for col in range(9):
			var angle: float=col*TAU/9.0+0.07*sin(row*2.0+col)
			var r: float=width*radii[row]*(1.0+0.065*sin(col*2.3+row))
			var y: float=height*levels[row]
			if row>0 and row<4: y+=height*0.033*sin(col*2.8+row)
			ring.append(at+Vector3(cos(angle)*r+lean*levels[row],y,sin(angle)*r))
		rings.append(ring)
	var palette := [Color("effbff"),Color("d9edf8"),Color("c8e1f0"),Color("b2c9e3"),Color("d1e6f6")]
	for row in range(4):
		for col in range(9):
			var next: int=(col+1)%9
			var color: Color=palette[(col+row*2)%palette.size()]
			ice_face(st,rings[row][col],rings[row+1][col],rings[row+1][next],color,col+row*9)
			ice_face(st,rings[row][col],rings[row+1][next],rings[row][next],color.lightened(0.025),col+row*9+3)
	finish(st,surface(emission),"GlacierMass")

func ice_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, index: int) -> void:
	triangle(st,a,b,c,color)
	var normal: Vector3=(b-a).cross(c-a).normalized()
	var p: Vector3=a.lerp(b,0.13)+normal*0.002
	var q: Vector3=a.lerp(b,0.68)+normal*0.002
	var r: Vector3=c.lerp(b,0.29)+normal*0.002
	triangle(st,p,q,r,Color("effaff") if index%3 else Color("b9d7ee"))
	if index%3==0:
		triangle(st,a.lerp(c,0.12)+normal*0.003,r,a.lerp(c,0.19)+normal*0.003,Color("8eadd7"))

func build_stone(variant: int) -> void:
	clear_pose()
	name="WeatheredMeteor_%02d" % variant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var forms := [Vector3(0.56,0.52,0.51),Vector3(0.66,0.46,0.49),Vector3(0.48,0.65,0.48),Vector3(0.61,0.53,0.46),Vector3(0.62,0.43,0.56),Vector3(0.57,0.55,0.52)]
	var shape: Vector3=forms[variant]
	var rings: Array[PackedVector3Array]=[]
	for row in range(7):
		var ring:=PackedVector3Array()
		var latitude: float=-PI/2+row*PI/6.0
		for col in range(12):
			var angle: float=col*TAU/12.0+0.08*sin(row*1.8)
			var rough: float=1.0+0.055*sin(col*2.3+row*3.7+variant*1.5)
			ring.append(Vector3(cos(angle)*cos(latitude),sin(latitude),sin(angle)*cos(latitude))*shape*rough)
		rings.append(ring)
	for row in range(6):
		for col in range(12):
			var next: int=(col+1)%12
			stone_face(st,rings[row][col],rings[row+1][col],rings[row+1][next],variant,row*24+col*2)
			stone_face(st,rings[row][col],rings[row+1][next],rings[row][next],variant,row*24+col*2+1)
	stone=finish(st,surface(),"FacetedWeatheredStone")
	var weather:=ShaderMaterial.new()
	weather.shader=preload("res://game/whispering_forest/art/combat/stone_weather.gdshader")
	stone.material_override=weather

func stone_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, variant: int, face: int) -> void:
	if (b-a).cross(c-a).length()<0.00001: return
	var grey: float=0.83+0.15*sin(face*2.71+variant*4.3)
	triangle(st,a,b,c,Color(0.42,0.48,0.53)*grey)
	# Local chips, soot patches and eroded seams sit on the actual facets.
	# They remain attached as the volume rotates under the fixed light.
	var n: Vector3=(b-a).cross(c-a).normalized()
	var center: Vector3=(a+b+c)/3+n*0.001
	if face%3!=0:
		var e: Vector3=a.lerp(b,0.47)+n*0.0015
		var f: Vector3=b.lerp(c,0.64)+n*0.0015
		triangle(st,center.lerp(e,0.7),e,f.lerp(center,0.5),Color("687882") if face%4 else Color("35414d"))
	if face%5==0:
		var start: Vector3=a.lerp(c,0.22)+n*0.003
		var end: Vector3=b.lerp(c,0.59)+n*0.003
		triangle(st,start,end,center.lerp(end,0.92),Color("303c47"))

func stone_pose(frame: int, variant: int) -> void:
	var phase: float=frame*TAU/FRAMES
	stone.quaternion=Quaternion(Vector3(0.6,0.3,0.74).normalized(),phase)*Quaternion(Vector3.UP,variant*0.49)

func wind_pose(frame: int) -> void:
	clear_pose()
	name="Gale_BroadCrescentRibbons"
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var phase: float=frame*TAU/FRAMES
	# Broad, curved brush masses supply the body. Tapered gaps keep the funnel
	# open; more thin coils would only make a denser wire cage at game scale.
	for strand in range(3):
		for i in range(144):
			var local: int=(i+strand*15)%48
			if local>=42: continue
			var u: float=i/144.0
			var v: float=(i+1)/144.0
			var a:=wind_edges(u,strand,phase,float(local)/42)
			var b:=wind_edges(v,strand,phase,float(local+1)/42)
			var color: Color=Color("d2e1e9").lerp(Color("f6fbff"),0.5+0.5*cos(u*TAU*2+phase+strand*TAU/3-0.7))
			triangle(st,a[0],a[1],b[1],color)
			triangle(st,a[0],b[1],b[0],color)
			# An uneven bright rim reads as a curled air sheet, not a flat stripe.
			var ar: Vector3=a[1].lerp(a[0],0.24+0.09*sin(u*56+strand))
			var br: Vector3=b[1].lerp(b[0],0.24+0.09*sin(v*56+strand))
			var lift:=Vector3(0,0.001,0)
			triangle(st,ar+lift,a[1]+lift,b[1]+lift,Color("ffffff"))
			triangle(st,ar+lift,b[1]+lift,br+lift,Color("ffffff"))
	var mat:=surface()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	finish(st,mat,"BroadBrokenWhorls")
	# A little rolling spray joins the funnel to the ground. It follows the
	# same periodic model pose; the root and canvas never follow its bounds.
	for i in range(7):
		var ball:=SphereMesh.new()
		ball.radius=0.038+0.009*(i%3)
		ball.height=ball.radius*2
		ball.radial_segments=8; ball.rings=4
		var puff:=MeshInstance3D.new()
		puff.mesh=ball; puff.material_override=mat
		var angle: float=phase+i*TAU/7
		puff.position=Vector3(cos(angle)*0.115,0.06+0.012*sin(angle*2),sin(angle)*0.115)
		add_child(puff)

func wind_edges(u: float, strand: int, phase: float, stroke: float) -> Array[Vector3]:
	var center:=wind_point(u,strand,phase)
	var taper: float=pow(maxf(0,sin(stroke*PI)),0.48)
	# Taper the whole helix as well as each brushstroke. Otherwise the first
	# and last partial strokes terminate in visibly squared-off paper edges.
	taper*=smoothstep(0,0.035,u)*(1.0-smoothstep(0.92,1.0,u))
	var width: float=(0.030+0.155*pow(u,0.65))*taper
	var edge: float=0.82+0.12*sin(u*59+strand*1.7)+0.10*sin(u*139+strand)
	var upper: float=0.92+0.08*sin(u*87+strand*2.4)
	return [center-Vector3(0,width*edge,0),center+Vector3(0,width*upper,0)]

func wind_point(u: float, strand: int, phase: float) -> Vector3:
	var angle: float=u*TAU*2.0+phase+strand*TAU/3
	var radius: float=0.07+0.76*pow(u,0.86)+0.024*sin(angle*3.0+u*8)
	return Vector3(cos(angle)*radius,u*2.15+0.035*sin(angle*2),sin(angle)*radius)
