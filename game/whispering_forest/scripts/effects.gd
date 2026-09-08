extends Node2D

var world: Node
var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var numbers: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var font: Font
var clock := 0.0

func burst(at: Vector2, color: Color, count: int = 16, force: float = 75.0) -> void:
	for i in range(count):
		particles.append({"at": at, "velocity": Vector2.from_angle(randf()*TAU) * randf_range(force*0.2,force), "height": randf_range(2,18), "lift": randf_range(10,55), "life": randf_range(0.3,0.7), "total": 0.7, "color": color, "size": randf_range(1.4,3.8)})

func circle(at: Vector2, radius: float, color: Color, duration: float = 0.55) -> void:
	rings.append({"at": at, "radius": radius, "color": color, "life": duration, "total": duration})

func number(at: Vector2, text: String, color: Color, large: bool = false) -> void:
	numbers.append({"at": WFIso.project(at)+Vector2(randf_range(-12,12),-70),"text":text,"color":color,"life":1.05,"age":0.0,"large":large})
	if numbers.size()>64: numbers.pop_front()

func step(delta: float) -> void:
	clock += delta
	for p in particles:
		p.life -= delta
		p.at += p.velocity * delta
		p.height += p.lift * delta
		p.lift -= delta * 95
	particles = particles.filter(func(p): return p.life > 0)
	for r in rings:
		r.life -= delta
	rings = rings.filter(func(r): return r.life > 0)
	for n in numbers:
		n.life -= delta
		n.age += delta
		n.at.y -= delta*(18.0+60.0*exp(-n.age*12.0))
	numbers = numbers.filter(func(n): return n.life > 0)
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var portal_at: Vector2 = world.START if world.area=="city" else world.DUNGEON_START
	var glow: float = 0.35+0.15*sin(clock*2)
	draw_polyline(WFIso.ring(portal_at,43),Color(0.64,0.93,1,glow),2,true)
	if world.arrival_glow>0:
		for i in range(10):
			var p := WFIso.project(portal_at)+Vector2(sin(i*2.4)*36,-fmod(clock*35+i*13,125))
			draw_circle(p,2,Color(0.77,0.94,1,minf(world.arrival_glow,1)*0.75))
	# Tiny drifting leaves and fireflies make the village feel alive.
	for i in range(32):
		var p := Vector2(sin(i*7.39)*720,cos(i*3.8)*330)
		p += Vector2(sin(clock*0.3+i)*22, sin(clock*0.6+i*4)*8)
		var a := 0.15+0.25*pow(sin(clock+i)*0.5+0.5,2)
		draw_circle(p,1.2,Color(0.78,0.91,0.84,a*0.7))
	for enemy in world.enemies:
		if not enemy.health.dead and enemy.windup > 0:
			var progress: float = 1.0-enemy.windup / 0.85
			var c := Color(0.86,0.25,0.12,0.16+progress*0.14)
			draw_colored_polygon(WFIso.disc(enemy.attack_target,40 if not enemy.elite else 65),c)
			c.a = 0.85
			draw_polyline(WFIso.ring(enemy.attack_target,(40 if not enemy.elite else 65)*progress),c,1.8,true)
	for r in rings:
		var progress: float = 1.0-r.life/r.total
		var c: Color = r.color
		c.a *= 1.0-progress
		draw_polyline(WFIso.ring(r.at, r.radius*(0.3+0.7*progress)),c,2.5,true)
	for bolt in world.projectiles:
		var release_offset: Vector2=bolt.get("muzzle",Vector2(0,-37))
		var flight: float=clampf(float(bolt.get("age",0))/maxf(0.01,float(bolt.get("flight",0.25))),0,1)
		var at: Vector2 = WFIso.project(bolt.at) + release_offset.lerp(Vector2(0,-37),flight)
		var dir: Vector2 = WFIso.project(bolt.direction).normalized()
		var col: Color = bolt.color
		var size: float = 6 if bolt.element == "fire" else 3
		draw_line(at-dir*29,at,Color(col,0.22),size*2.8,true)
		draw_line(at-dir*17,at,Color(col,0.75),size*1.5,true)
		draw_circle(at,size+5,Color(col,0.14))
		draw_circle(at,size,col)
		draw_circle(at+dir*2,size*0.52,Color("fff2c6"))
	for p in particles:
		var col: Color = p.color
		col.a = clampf(p.life/p.total,0,1)
		draw_circle(WFIso.project(p.at)+Vector2(0,-p.height),p.size,col)
	if world.meteor_timer > 0:
		var progress: float = 1.0-world.meteor_timer/1.3
		var p := WFIso.project(world.meteor_target)
		var ring := WFIso.ring(world.meteor_target,125)
		draw_colored_polygon(WFIso.disc(world.meteor_target,125),Color(1,0.4,0.08,0.13+progress*0.12))
		draw_polyline(ring,Color(1,0.74,0.33,0.9),2,true)
		for i in range(6):
			var a := p+Vector2.from_angle(i*TAU/6+clock)*Vector2(100,50)
			var b := p+Vector2.from_angle((i+2)*TAU/6+clock)*Vector2(100,50)
			draw_line(a,b,Color(1,0.77,0.4,0.7),1.4,true)
		# Falling body is a separate depth-sorted textured meteor in SpellSystem.
	for n in numbers:
		var col: Color = n.color
		col.a *= minf(n.life*3,1)
		var punch: float = sin(minf(n.age/0.18,1.0)*PI)*exp(-n.age*5)
		var size := roundi((28.0 if n.large else 20.0)*(1.0+punch*0.45))
		var at: Vector2 = n.at-Vector2(font.get_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5,0)
		draw_string_outline(font,at,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0.12,0.18,0.14,col.a))
		draw_string(font,at,n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
