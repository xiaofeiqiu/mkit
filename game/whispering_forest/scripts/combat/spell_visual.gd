extends Node2D

const Art = preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd")
const Timing = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const FireCue = preload("res://game/whispering_forest/scripts/combat/fire_cue.gd")

# Material sprites, animation frames and ground-anchored particles share the
# actors' isometric projection. Reference-game footage is never used as an asset.
var kind := "fire"
var age := 0.0
var duration := 1.0
var radius := 60.0
var level := 1
var ground := Vector2.ZERO
var variant := 0.0
var art_frames: Array[Texture2D] = []
var rock_index := 0
var rock_scale := 1.0
var impact_at := 0.95
var fade_at := 0.0
var fade_span := 0.9
var fade_from := 1.0
var ending := false
var launch_at := 0.0
var puff_frames: Array[Texture2D] = []
var trail: Array[Dictionary] = []
var next_puff_age := 0.0
var spin_rate := 3.8
var rotation_poses: Array[Vector2] = []
var rock_frames: Array = []
var fixed_ground := Vector2.ZERO
var body: Sprite2D
var body_material: ShaderMaterial

func setup(effect: String, at: Vector2, size_value: float, rank: int, lifetime: float) -> void:
	kind=effect; ground=at; radius=size_value; level=rank; duration=lifetime
	fixed_ground=at
	variant=randf()*TAU
	rock_index=randi()%6
	rock_scale=randf_range(0.90,1.10)
	spin_rate=randf_range(3.2,4.9)*(1.0 if randi()%2 else -1.0)
	if kind=="ultimate_fall": spin_rate*=0.65
	impact_at=lifetime
	if kind=="ultimate_fall": duration+=1.0
	if kind=="ultimate_burst": duration=maxf(duration,2.4)
	if kind=="fire" and level==1: duration=FireCue.duration()
	fade_span=minf(duration,{"fire":0.9,"ultimate_burst":0.9,"wind":0.9,"earth":0.9,"ultimate_fall":0.9,"ice":Timing.ICE_FADE}.get(kind,0.6))
	if kind=="fire" and level==1: fade_span=duration*0.70
	fade_at=duration-fade_span
	position=WFIso.project(ground)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	if kind in ["earth","ultimate_fall"]:
		for i in range(6): rock_frames.append(Art.clip("earth",i))
		art_frames=rock_frames[rock_index]
		puff_frames=Art.frames("meteor-puffs-v1")
		for i in range(art_frames.size()):
			var u:=float(i)/(art_frames.size()-1)
			rotation_poses.append(Vector2(u,0.93+0.07*cos(u*TAU+variant)))
	elif kind in ["fire","ultimate_burst"]: art_frames=Art.clip("fire")
	elif kind in ["wind","ice"]: art_frames=Art.clip(kind)
	if kind in ["fire","ultimate_burst","wind","ice","earth","ultimate_fall"]:
		body=Sprite2D.new()
		body.centered=false
		body.visible=false
		body_material=ShaderMaterial.new()
		body_material.shader=preload("res://game/whispering_forest/scripts/combat/clip_blend.gdshader")
		body.material=body_material
		add_child(body)
	self_modulate.a=opacity()

func draw_body(textures: Array, frame: float, rect: Rect2, tint: Color = Color.WHITE, loop: bool = false) -> void:
	var first:=int(frame)
	var next:=((first+1)%textures.size()) if loop else mini(first+1,textures.size()-1)
	for item in [["a",textures[first]],["b",textures[next]]]:
		var texture: AtlasTexture=item[1]
		var atlas_size:=texture.atlas.get_size()
		var canvas:=texture.get_size()
		var r:=Rect2(texture.region.position/atlas_size,texture.region.size/atlas_size)
		var p:=Rect2(texture.margin.position/canvas,texture.region.size/canvas)
		body_material.set_shader_parameter("frame_"+item[0],texture.atlas)
		body_material.set_shader_parameter("region_"+item[0],Vector4(r.position.x,r.position.y,r.size.x,r.size.y))
		body_material.set_shader_parameter("placement_"+item[0],Vector4(p.position.x,p.position.y,p.size.x,p.size.y))
	body_material.set_shader_parameter("phase",fmod(frame,1))
	body.texture=textures[first].atlas
	body.position=rect.position
	body.scale=rect.size/body.texture.get_size()
	body.modulate=Color(tint,tint.a*opacity())
	body.visible=true

func opacity() -> float:
	# Ice cels author their own solid fracture/removal; never expose actors or
	# terrain through the body by applying the generic translucent spell tail.
	if kind=="ice": return 1.0
	var alpha:=fade_from*(1.0-smoothstep(fade_at,fade_at+fade_span,age))
	if kind=="fire" and level==1: alpha=pow(alpha,1.7)
	if kind=="wind" and not ending: alpha*=smoothstep(0,0.4,age)
	return alpha

func begin_fade(seconds: float) -> void:
	if ending: return
	# Keep the current opacity and animation phase: shortening the original
	# lifetime would jump to a different atlas frame and pop at the collision.
	fade_from=opacity()
	ending=true
	fade_at=age
	fade_span=seconds
	duration=age+seconds

func advance(delta: float) -> void:
	age+=delta
	# Stationary spells retain the launch snapshot even if their former target
	# moves, dies, is knocked back or is removed. Only wind travels afterward.
	if kind!="wind": ground=fixed_ground
	if kind in ["earth","ultimate_fall"]:
		next_puff_age=maxf(next_puff_age,launch_at+0.025)
		while next_puff_age<=minf(age,impact_at):
			var seed_value:=next_puff_age*137+variant
			var offset:=Vector2(sin(seed_value)*radius*0.12,-radius*0.35)
			trail.append({"born":next_puff_age,"at":meteor_position(next_puff_age)+offset,
				"life":0.34+0.10*(0.5+0.5*sin(seed_value)),"seed":seed_value})
			next_puff_age+=0.045
		trail=trail.filter(func(p): return age-float(p.born)<float(p.life))
	position=WFIso.project(ground)
	self_modulate.a=opacity()
	queue_redraw()

func _ellipse(at: Vector2, r: float, color: Color, width: float = 0.0) -> void:
	var points:=PackedVector2Array()
	for i in range(49): points.append(at+Vector2(cos(i*TAU/48.0)*r,sin(i*TAU/48.0)*r*0.48))
	if width>0: draw_polyline(points,color,width,true)
	else: draw_colored_polygon(points,color)

func _draw() -> void:
	var t:=clampf(age/duration,0,1)
	match kind:
		"fire","ultimate_burst": _fire(t)
		"wind": _tornado(t)
		"earth","ultimate_fall": _meteor(t)
		"impact": _impact(t)
		"ice": _ice(t)
		"spawn":
			_ellipse(Vector2.ZERO,radius*(0.7+0.3*t),Color(0.9,0.35,0.2,(1-t)*0.4),2)
			for i in range(5):
				var a:=i*TAU/5
				draw_line(Vector2.from_angle(a)*radius*Vector2(1,0.5),Vector2.from_angle(a)*radius*0.65*Vector2(1,0.5),Color(1,0.64,0.38,1-t),2,true)

func _fire(t: float) -> void:
	_ellipse(Vector2.ZERO,radius*(0.4+0.7*t),Color(0.19,0.075,0.035,0.26*(1-t)))
	var times: Array=FireCue.pose_times() if kind=="fire" and level==1 else [0.0,0.15,0.36,0.65,1.05,1.40,1.85,2.4]
	var f:=timed_frame(times,age)
	var size_value:=Vector2.ONE*radius*2.5
	var rect:=Rect2(Vector2(0,-radius*0.65)-size_value*0.5,size_value)
	draw_body(art_frames,f,rect)
	
	# Airborne embers follow ballistic arcs around the rolling flame animation.
	for i in range(4+level):
		var a:=i*2.399+variant
		var speed:=radius*(0.7+0.07*(i%7))
		var at:=Vector2(cos(a),sin(a)*0.48)*speed*t*1.9
		at.y-=sin(t*PI)*radius*(0.55+0.06*(i%5))
		var tail:=Vector2(cos(a)*5,-6)*(1-t)
		draw_line(at,at-tail,Color(1,0.63+0.03*(i%4),0.16,(1-t)*0.8),1.3+float(i%3)*0.5,true)

func _tornado(_t: float) -> void:
	var height:=radius*3.5
	_ellipse(Vector2.ZERO,radius*0.68,Color(0.1,0.25,0.25,0.08))
	# Eight broad-ribbon poses at 8 fps. Lifetime and the 0.9 s dissolve are
	# independent from the one-second rotation cycle.
	var frame:=fposmod(age*8.0+variant,8.0)
	var display_scale: float=Art.solid_data("wind").runtime_scale*radius/23.0
	var size_value:=art_frames[0].get_size()*display_scale
	var rect:=Rect2(-Art.pivot("wind")*display_scale,size_value)
	draw_body(art_frames,frame,rect,Color(1,1,1,0.84),true)
	for i in range(3+int(level/3)):
		var u:=fposmod(age*0.38+float(i)*0.29,1)
		var a:=age*4.5+i*2.4
		var at:=Vector2(cos(a)*radius*(0.25+0.55*u),sin(a)*radius*0.3-u*height)
		draw_line(at,at+Vector2(2*cos(a),1.5),Color(0.79,0.9,0.8,0.6),1,true)

func _rock(at: Vector2, size_value: float, angle: float, tint: Color) -> void:
	var points:=PackedVector2Array()
	for i in range(7):
		var a:=angle+i*TAU/7
		points.append(at+Vector2.from_angle(a)*size_value*(0.85+0.13*sin(i*9.7)))
	var center:=at+Vector2(-size_value*0.18,-size_value*0.22)
	for i in range(7):
		var shade:=0.67+0.33*(0.5+0.5*cos(i*TAU/7+angle+2.1))
		draw_colored_polygon(PackedVector2Array([center,points[i],points[(i+1)%7]]),Color(tint*shade,tint.a))
	draw_line(points[0],center,tint.lightened(0.22),1,true)
	draw_line(center,points[4],tint.darkened(0.25),1,true)

func _meteor(_t: float) -> void:
	if age<launch_at: return
	var ultimate:=kind=="ultimate_fall"
	var travel:=clampf((age-launch_at)/maxf(impact_at-launch_at,0.01),0,1)
	var fall:=pow(travel,1.7)
	var settled:=clampf((age-impact_at)/0.30,0,1)
	_ellipse(Vector2.ZERO,radius*(0.25+0.7*fall),Color(0.12,0.14,0.17,0.22*fall))
	_ellipse(Vector2.ZERO,radius,Color(0.66,0.73,0.80,0.30*(1-settled)),1.1)
	var at:=meteor_position(age)+Vector2(0,settled*7)
	# Puffs are left at historical flight positions rather than attached to the
	# stone. They survive impact briefly and disperse with their own lifetimes.
	for puff in trail:
		var u:=clampf((age-float(puff.born))/float(puff.life),0,1)
		var puff_at: Vector2=puff.at+Vector2(sin(puff.seed)*u*8,-u*10)
		var tex: Texture2D=puff_frames[mini(3,int(u*4))]
		var size_value:=tex.get_size()/maxf(tex.get_width(),tex.get_height())*radius*(0.30+u*0.12)
		var color:=Color(1,0.92,0.80,pow(1-u,0.7)*0.95) if ultimate else Color(1,1,1,pow(1-u,0.7)*0.95)
		draw_texture_rect(tex,Rect2(puff_at-size_value*0.5,size_value),false,color)
	var phase:=fposmod(meteor_angle(age)/TAU*8,8)
	var textures: Array=rock_frames[rock_index]
	var display_scale: float=Art.solid_data("earth").runtime_scale*radius/38.0*rock_scale*(1.0-settled*0.20)
	var rect:=Rect2(at-Art.pivot("earth")*display_scale,textures[0].get_size()*display_scale)
	var stone_tint:=Color("ffd6ac") if ultimate else Color.WHITE
	stone_tint.a=smoothstep(launch_at,launch_at+0.10,age)
	# True 3D rotations were baked under the fixed world light. No sprite spin
	# or non-uniform screen scaling is used to fake different stone faces.
	draw_body(textures,phase,rect,stone_tint,true)
	if ultimate: _rock(at+Vector2(-3,-3),radius*0.24,age*2,Color(1,0.65,0.12,0.4))

func meteor_position(at_age: float) -> Vector2:
	var t:=clampf((at_age-launch_at)/maxf(impact_at-launch_at,0.01),0,1)
	var fall:=pow(t,1.7)
	return Vector2((1-fall)*radius*1.8,-(1-fall)*(235+radius)-12)

func meteor_angle(at_age: float) -> float:
	return variant+meteor_pose(at_age).x*(impact_at-launch_at)*spin_rate

func meteor_pose(at_age: float) -> Vector2:
	var phase:=clampf((at_age-launch_at)/maxf(impact_at-launch_at,0.01),0,1)*7
	var index:=mini(6,int(phase))
	return rotation_poses[index].lerp(rotation_poses[index+1],phase-index)

func animation_frame_count() -> int:
	return rotation_poses.size() if kind in ["earth","ultimate_fall"] else art_frames.size()

func _impact(t: float) -> void:
	for i in range(8):
		var a:=i*2.399+variant
		var d:=Vector2.from_angle(a)*radius*(0.5+0.4*t)*Vector2(1,0.5)
		draw_line(d*0.16,d*0.68,Color(0.20,0.22,0.24,(1-t)*0.75),2,true)
		draw_line(d*0.68,d+Vector2(5,-2),Color(0.20,0.22,0.24,(1-t)*0.7),1.4,true)
	for i in range(12+level):
		var a:=i*2.399+variant
		var at:=Vector2.from_angle(a)*radius*t*(0.7+float(i%4)*0.15)*Vector2(1,0.5)
		at.y-=sin(t*PI)*radius*(0.3+float(i%5)*0.1)
		_rock(at,(2+float(i%4))*(1-t*0.5),age*3+i,Color(0.52,0.56,0.60,1-t))
	_ellipse(Vector2.ZERO,radius*(0.35+t),Color(0.58,0.63,0.67,(1-t)*0.24),6*(1-t)+1)

func _crystal(at: Vector2, width: float, height: float, alpha: float, lean: float) -> void:
	var base_l:=at+Vector2(-width,0)
	var base_r:=at+Vector2(width,width*0.25)
	var tip:=at+Vector2(lean,-height)
	var shoulder_l:=at+Vector2(-width*0.7,-height*0.68)
	var shoulder_r:=at+Vector2(width*0.8,-height*0.64)
	var spine:=at+Vector2(-width*0.10,-height*0.28)
	draw_colored_polygon(PackedVector2Array([base_l,shoulder_l,tip,spine]),Color(0.68,0.91,1,alpha))
	draw_colored_polygon(PackedVector2Array([spine,tip,shoulder_r,base_r]),Color(0.30,0.59,0.81,alpha))
	draw_colored_polygon(PackedVector2Array([base_l,spine,base_r,at+Vector2(0,width*0.62)]),Color(0.47,0.74,0.91,alpha))
	draw_colored_polygon(PackedVector2Array([shoulder_l,tip,spine]),Color(0.86,0.98,1,alpha*0.78))
	draw_line(shoulder_l,tip,Color(0.98,1,1,alpha),1.5,true)
	draw_line(tip,spine,Color(0.88,0.99,1,alpha*0.85),1,true)
	draw_line(at+Vector2(-width*0.4,-height*0.28),at+Vector2(width*0.2,-height*0.39),Color(1,1,1,alpha*0.65),1,true)

func ice_stage() -> String:
	if age<Timing.ICE_RISE: return "gather"
	if age<Timing.ICE_PEAK: return "rise"
	if age<Timing.ICE_SETTLE: return "peak"
	return "fracture" if age<fade_at else "shatter"

func ice_height() -> float:
	var f:=ice_frame()
	var heights: Array=Art.solid_data("ice").heights_metres
	var height: float=lerpf(heights[int(f)],heights[mini(heights.size()-1,int(f)+1)],fmod(f,1))
	return height*32*sqrt(2.0)*cos(PI/6)*radius/36.0

func ice_frame() -> float:
	var asset:=Art.solid_data("ice")
	# Aseprite holds every authored cel for its own duration. In particular,
	# keep the eruption crisp instead of crossfading two separated ice tips.
	for i in range(asset.times.size()-1):
		if age<float(asset.times[i+1]): return float(i)
	return float(asset.times.size()-1)

func timed_frame(times: Array, at_age: float) -> float:
	for i in range(times.size()-1):
		if at_age<float(times[i+1]):
			return i+smoothstep(float(times[i]),float(times[i+1]),at_age)
	return float(times.size()-1)

func _ice(_t: float) -> void:
	# Sixteen Aseprite cels share one projected origin and fixed canvas.
	# The spear erupts through the floor, then fractures without contracting.
	var frame:=ice_frame()
	var display_scale: float=Art.solid_data("ice").runtime_scale*radius/36.0
	var rect:=Rect2(-Art.pivot("ice")*display_scale,art_frames[0].get_size()*display_scale)
	draw_body(art_frames,frame,rect)
