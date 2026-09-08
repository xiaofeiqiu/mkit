extends RefCounted

static func build(world: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1409
	if world.area=="city":
		var layout: Node2D = load("res://game/whispering_forest/city_layout.tscn").instantiate()
		world.sorted_world.add_child(layout)
		for prop in layout.get_children():
			prop.world = world
			if prop.has_method("blocks"): world.props.append(prop)
		for i in range(world.City.STATIONS.size()): world.add_waystone(i)
	else:
		# A separate forest clearing: no houses, city NPCs, or city combat.
		for at in [Vector2(-340,-330),Vector2(-100,-280),Vector2(95,-290),Vector2(270,-200),Vector2(395,-130),Vector2(-420,105),Vector2(-105,285),Vector2(125,310),Vector2(330,240),Vector2(420,70),Vector2(-365,390)]:
			world.add_prop("tree",at,rng.randf_range(210,258),20)
		for i in range(35):
			var a := TAU*i/35
			world.add_prop("tree",Vector2(cos(a),sin(a))*rng.randf_range(545,650),rng.randf_range(210,270),22)
		for at in [Vector2(-140,-155),Vector2(100,-116),Vector2(240,-105),Vector2(310,120),Vector2(85,220),Vector2(-170,265),Vector2(-330,210),Vector2(-350,65),Vector2(-10,-245)]:
			world.add_prop("shrub",at,rng.randf_range(32,48),0,false)
