extends Node2D

const Actor = preload("res://game/whispering_forest/scripts/combat/performer.gd")
const ImpactFeedback = preload("res://game/whispering_forest/scripts/combat/impact_feedback.gd")
const Prop = preload("res://game/whispering_forest/scripts/prop.gd")
const CityNavigation = preload("res://game/whispering_forest/scripts/city_navigation.gd")
const CityGround = preload("res://game/whispering_forest/scripts/city_ground.gd")
const Terrain = preload("res://game/whispering_forest/scripts/terrain.gd")
const Effects = preload("res://game/whispering_forest/scripts/effects.gd")
const Hud = preload("res://game/whispering_forest/scripts/hud.gd")
const Profile = preload("res://game/whispering_forest/scripts/profile.gd")
const Maps = preload("res://game/whispering_forest/scripts/maps.gd")
const City = preload("res://game/whispering_forest/scripts/city.gd")
const SpellSystem = preload("res://game/whispering_forest/scripts/combat/spell_system.gd")
const WaveDirector = preload("res://game/whispering_forest/scripts/combat/wave_director.gd")
const MusicDirector = preload("res://game/whispering_forest/scripts/music_director.gd")
const QUEST_ID := "wf.Q101.goblin_hat"
const PROFILE_PATH := "user://whispering_forest_sample_v1.json"
const START := Vector2(-60, 60)
const DUNGEON_START := Vector2(-120,85)
const LIMIT := 530.0
const CAMERA_LEAD := Vector2(105,-90)

class AttackReceiver:
	extends CommandReceiver
	var world: Node
	func handle_unhandled_command(command: GameCommand) -> bool:
		if command.command_type != "wf.attack":
			return false
		return world.perform_attack()

var player: WFActor
var mentor: WFActor
var enemies: Array[WFActor] = []
var props: Array[Node2D] = []
var sorted_world: Node2D
var terrain: Node2D
var effects: Node2D
var hud: Control
var camera: Camera2D
var profile: Saveable
var environment_atlas: Texture2D
var projectiles: Array[Dictionary] = []
var stage := 0
var area := "city"
var waystones: Array[Node2D] = []
var travel_open := false
var travel_origin := -1
var intro_seen := false
var arrival_glow := 0.0
var language := "zh"
var rage := 0.0
var kills := 0
var wave := 1
var muted := false
var auto_attack := true
var paused := false
var dialogue: Array = []
var dialogue_index := 0
var dialogue_action := ""
var toast_zh := ""
var toast_en := ""
var toast_timer := 0.0
var skill_cooldowns: Array[float] = [0.0,0.0,0.0,0.0,0.0]
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var dodge_timer := 0.0
var dodge_direction := Vector2.ZERO
var last_direction := Vector2(1,0)
var click_destination := Vector2.ZERO
var click_moving := false
var click_path := PackedVector2Array()
var city_navigation: RefCounted
var rage_hit_timer := 0.0
var meteor_timer := 0.0
var meteor_target := Vector2.ZERO
var wave_timer := 0.0
var screen_shake := 0.0
var elapsed := 0.0
var autosave_timer := 0.0
var simulation := false
var capture_mode := false
var capture_path := ""
var review_mode := false
var capture_language := "zh"
var capture_dialogue := false
var capture_dungeon := false
var capture_travel := false
var capture_overview := false
var capture_station := -1
var showcase_mode := false
var walk_showcase := false
var city_tour := false
var showcase_direction := Vector2.ZERO
var sound_nodes: Array[AudioStreamPlayer] = []
var ambient: MusicDirector
var restart_armed := false
var receiver: CommandReceiver
var last_save_success := true
var spells: Node
var expedition: Node
var combat_review := false
var combat_test := false
var impact: Node2D
var feel_review := false
var feel_test := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg in ["--wf-feel-review","--wf-feel-test"]:
			feel_review = true
			feel_test = arg=="--wf-feel-test"
			capture_mode = true
		if arg in ["--wf-combat-review","--wf-combat-test"]:
			combat_review=true
			capture_mode=true
			combat_test=arg=="--wf-combat-test"
		if arg == "--wf-smoke":
			simulation = true
		if arg == "--wf-review":
			review_mode = true
		if arg == "--wf-en":
			capture_language = "en"
		if arg == "--wf-dialogue":
			capture_dialogue = true
		if arg == "--wf-dungeon":
			capture_dungeon = true
		if arg == "--wf-travel":
			capture_travel = true
		if arg == "--wf-overview":
			capture_overview = true
		if arg.begins_with("--wf-station="):
			capture_station = arg.trim_prefix("--wf-station=").to_int()
		if arg == "--wf-showcase":
			showcase_mode = true
			capture_mode = true
		if arg == "--wf-city-tour":
			showcase_mode = true
			capture_mode = true
			city_tour = true
		if arg == "--wf-walk-showcase":
			showcase_mode = true
			capture_mode = true
			walk_showcase = true
		if arg.begins_with("--wf-capture="):
			capture_mode = true
			capture_path = arg.trim_prefix("--wf-capture=")
	RenderingServer.set_default_clear_color(Color("2f4933"))
	DisplayServer.window_set_title("Whispering Forest · 晨铃城与哥布林副本")
	environment_atlas = load("res://game/whispering_forest/assets/environment-green.png")
	_build_world()
	_build_quest()
	profile = Profile.new()
	profile.world = self
	add_child(profile)
	Mkit.save().save_path = PROFILE_PATH
	Mkit.save().game_version = "whispering-forest-development-0.6"
	if not simulation and not capture_mode and not review_mode and FileAccess.file_exists(PROFILE_PATH):
		if not Mkit.save().load_game(get_tree().root):
			toast("存档暂时无法读取，本次以新旅程开始。","Could not load the save. Starting a fresh visit.")
	_build_audio()
	get_tree().auto_accept_quit = false
	if feel_review:
		var review = load("res://game/whispering_forest/tools/feel_review.gd").new()
		review.world = self
		add_child(review)
	elif combat_review:
		var review=load("res://game/whispering_forest/tools/combat_review.gd").new()
		review.world=self
		add_child(review)
	elif simulation:
		_smoke_test.call_deferred()
	elif showcase_mode:
		if city_tour:
			_city_tour.call_deferred()
		elif walk_showcase:
			_walk_showcase.call_deferred()
		else:
			_showcase.call_deferred()
	elif capture_mode:
		_capture.call_deferred()
	else:
		if not intro_seen:
			_begin_arrival()
		else:
			toast("晨铃城是安全区域。靠近梅尔，按 E 接取副本任务。","Bellwake is safe. Press E near Mel to enter a quest instance.",7)

func _build_world() -> void:
	_build_map()
	player = _actor("mage",START,120)
	player.name = "Traveler"
	player.health.died.connect(_player_died)
	receiver = AttackReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.receiver_id = "wf.player"
	receiver.auto_register = false
	receiver.world = self
	player.add_child(receiver)
	Mkit.commands().register_receiver("wf.player",receiver)
	camera = Camera2D.new()
	camera.position = player.position+CAMERA_LEAD
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2.ONE * 1.1
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.world = self
	layer.add_child(hud)
	effects = Effects.new()
	effects.world = self
	effects.font = hud.font
	effects.z_index = 20
	add_child(effects)
	impact = ImpactFeedback.new()
	impact.world = self
	add_child(impact)
	spells=SpellSystem.new()
	spells.world=self
	add_child(spells)
	expedition=WaveDirector.new()
	expedition.world=self
	add_child(expedition)

func _build_map() -> void:
	terrain = Node2D.new() if area=="city" else Terrain.new()
	if area!="city": terrain.world = self
	terrain.z_index = -10
	add_child(terrain)
	sorted_world = Node2D.new()
	sorted_world.name = "BellwakeCity" if area=="city" else "GoblinQuestInstance"
	sorted_world.y_sort_enabled = true
	add_child(sorted_world)
	Maps.build(self)
	city_navigation = null
	click_path.clear()
	if area=="city":
		city_navigation = CityNavigation.new()
		city_navigation.build(self)
	if area=="city":
		mentor = _actor("mentor",Vector2(-110,5),100)
		mentor.name = "Mel"
		mentor.facing = 0

func _change_area(next_area: String) -> void:
	impact.reset()
	spells.reset()
	expedition.reset()
	# Unload the previous map entirely. The city and instance never share enemies.
	player.reparent(self)
	remove_child(sorted_world)
	sorted_world.queue_free()
	remove_child(terrain)
	terrain.queue_free()
	mentor = null
	enemies.clear()
	props.clear()
	waystones.clear()
	travel_open = false
	travel_origin = -1
	projectiles.clear()
	effects.particles.clear()
	effects.rings.clear()
	effects.numbers.clear()
	area = next_area
	paused = false
	_build_map()
	player.reparent(sorted_world)
	player.ground = START if area=="city" else DUNGEON_START
	player.call("reset_performance")
	player.position = WFIso.project(player.ground)
	player.moving = false
	player.health.revive(1.0)
	player.invincible = 3
	click_moving = false
	dodge_timer = 0
	meteor_timer = 0
	wave_timer = 0
	skill_cooldowns.fill(0.0)
	camera.position = player.position+CAMERA_LEAD
	arrival_glow = 2.5

func enter_dungeon() -> void:
	if stage not in [1,3]:
		return
	_change_area("dungeon")
	if stage==1:
		_spawn_trial()
	else:
		_spawn_wave()
	toast("传送完成 · 独立哥布林副本 · B 可返回城内","Arrived in the goblin instance · B returns to the city",6)
	play_sound("seal")
	save_profile()

func return_to_city() -> void:
	if area!="dungeon":
		return
	_change_area("city")
	toast("已回到晨铃城 · 找梅尔交付或重新接取副本","Back in Bellwake · Speak to Mel to turn in or re-enter",6)
	play_sound("bell")
	save_profile()

func _begin_arrival() -> void:
	arrival_glow = 3.5
	dialogue_index = 0
	dialogue = [["站稳，召唤已经结束。这里是晨铃城，\n与你原来的世界不同。","Easy now. The summoning is over. This is Bellwake,\na different world from the one you knew."],["我们向界外发出了求援，而你回应了。\n先缓一缓；这里是安全的，你不必立刻作出承诺。","We called beyond our world for help, and you answered.\nRest first. You are safe here; you owe us no promise."],["等你准备好，再来找我。先做一次简单的就职试炼，\n我会把你传送到城外的哥布林副本。","When you are ready, speak to me about a simple trial.\nI will send you to a separate goblin instance beyond the city."]]
	dialogue_action = "arrival"
	play_sound("seal")

func _collision_marker(at: Vector2, radius: float) -> Node2D:
	var marker := Prop.new()
	marker.ground = at
	marker.radius = radius
	marker.fadeable = false
	marker.world = self
	sorted_world.add_child(marker)
	return marker

func add_prop(kind: String, at: Vector2, width: float, radius: float, fadeable: bool = true) -> void:
	# Measured transparent separators in the 1284 x 1225 revised atlas.
	var regions := {"tree":Rect2(0,0,680,728),"cottage":Rect2(690,0,594,728),"gate":Rect2(0,728,680,497),"shrub":Rect2(690,728,594,497)}
	var prop := Prop.new()
	var region: Rect2 = regions[kind]
	var atlas_scale := Vector2(environment_atlas.get_width(),environment_atlas.get_height()) / Vector2(1284,1225)
	region = Rect2(region.position*atlas_scale,region.size*atlas_scale)
	prop.setup(WFIso.atlas(environment_atlas,region),at,width,radius,self,fadeable)
	sorted_world.add_child(prop)
	props.append(prop)

func add_city_gate(at: Vector2) -> void:
	const PATH := "res://game/whispering_forest/assets/city-gate.png"
	if not ResourceLoader.exists(PATH):
		add_prop("gate",at,280,0)
		return
	var texture: Texture2D = load(PATH)
	var region := Rect2(texture.get_image().get_used_rect())
	var prop := Prop.new()
	prop.setup(WFIso.atlas(texture,region),at,310,0,self,true)
	sorted_world.add_child(prop)
	props.append(prop)
	props.append(_collision_marker(at+Vector2(-45,55),24))
	props.append(_collision_marker(at+Vector2(53,-38),24))

func add_waystone(index: int) -> void:
	var prop := preload("res://game/whispering_forest/scripts/city_sprite.gd").new()
	prop.asset="waystone"
	prop.ground=City.STATIONS[index].at
	prop.radius=15
	prop.world=self
	prop.fadeable=false
	sorted_world.add_child(prop)
	props.append(prop)
	waystones.append(prop)

func open_travel() -> void:
	if area!="city" or not dialogue.is_empty():
		return
	travel_origin = City.station_near(player.ground,75)
	if travel_origin<0:
		return
	travel_open = true
	click_moving = false
	dodge_timer = 0
	player.moving = false
	play_sound("bell")

func close_travel() -> void:
	travel_open = false
	travel_origin = -1

func travel_to(index: int) -> void:
	if not travel_open or area!="city" or index<0 or index>=City.STATIONS.size():
		return
	var station: Dictionary = City.STATIONS[index]
	if not walkable(station.landing):
		toast("传送落点暂时不可用。","This arrival point is temporarily unavailable.")
		return
	player.ground = station.landing
	player.position = WFIso.project(player.ground)
	player.moving = false
	click_moving = false
	dodge_timer = 0
	camera.position = player.position+CAMERA_LEAD
	camera.offset = Vector2.ZERO
	effects.burst(player.ground,Color("a9e8ef"),32,65)
	effects.circle(player.ground,45,Color("9edfea"),0.9)
	close_travel()
	toast("已传送至 "+station.zh,"Arrived at "+station.en,3)
	play_sound("seal")

func district_name() -> String:
	var station: Dictionary = City.STATIONS[City.station_near(player.ground)]
	return say(station.zh,station.en)

func _actor(kind: String, at: Vector2, hp: float, elite: bool = false) -> WFActor:
	var actor := Actor.new()
	actor.setup(kind,at,hp,self,elite)
	sorted_world.add_child(actor)
	actor.health.stats = actor.stats_component
	return actor

func portrait_texture() -> Texture2D:
	return WFIso.atlas(load("res://game/whispering_forest/assets/characters/world-motion/mage-idle.png"),Rect2(83,7*256+47,104,120))

func bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style

func _build_quest() -> void:
	if Mkit.content().has(QUEST_ID):
		return
	var definition := QuestDefinition.new()
	definition.quest_id = QUEST_ID
	definition.display_name = "A Goblin's Hat"
	definition.description = "Bring the trial goblin's hat to Mel."
	definition.auto_complete = false
	var objective := QuestObjectiveDefinition.new()
	objective.objective_id = "hat"
	objective.event_type = "wf.hat_collected"
	objective.required_count = 1
	definition.objectives = [objective]
	Mkit.content().register_resource(definition)

func _spawn_trial() -> void:
	if area!="dungeon" or not enemies.is_empty():
		return
	var goblin := _actor("goblin",Vector2(90,85),60)
	goblin.name = "T101_TrialGoblin"
	goblin.health.died.connect(func(_actor_node): _enemy_died(goblin))
	enemies.append(goblin)

func _spawn_wave() -> void:
	if area!="dungeon":
		return
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	expedition.start()

func _process(delta: float) -> void:
	if simulation:
		return
	step(delta)

func step(delta: float) -> void:
	elapsed += delta
	arrival_glow = maxf(0,arrival_glow-delta)
	toast_timer = maxf(0,toast_timer-delta)
	if paused or travel_open:
		effects.queue_redraw()
		return
	if not expedition.card_choices.is_empty(): return
	if not dialogue.is_empty():
		player.moving = false
		player.step(delta)
		if is_instance_valid(mentor):
			mentor.moving = false
			mentor.step(delta)
		effects.step(delta)
		return
	attack_cooldown = maxf(0,attack_cooldown-delta)
	dodge_cooldown = maxf(0,dodge_cooldown-delta)
	rage_hit_timer = maxf(0,rage_hit_timer-delta)
	for i in range(skill_cooldowns.size()):
		skill_cooldowns[i] = maxf(0,skill_cooldowns[i]-delta)
	var input := Vector2.ZERO
	if not capture_mode:
		input = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction := WFIso.unproject(input).normalized()
	if showcase_mode:
		direction = showcase_direction
	if input != Vector2.ZERO:
		click_moving = false
	elif click_moving:
		if player.ground.distance_to(click_destination)<7:
			if not click_path.is_empty():
				click_destination = click_path[0]
				click_path.remove_at(0)
			else: click_moving = false
		direction = (click_destination-player.ground).normalized() if click_moving else Vector2.ZERO
	if dodge_timer > 0:
		dodge_timer -= delta
		direction = dodge_direction
	if direction != Vector2.ZERO:
		last_direction = direction
	player.moving = direction != Vector2.ZERO and meteor_timer <= 0 and not player.call("is_recovering")
	if player.moving:
		var before := player.ground
		move_actor(player,direction * (430.0 if dodge_timer>0 else 135.0*(1.0+float(spells.modifiers.get("move",0))))*delta)
		if player.attack_pose<=0: player.face(direction)
		if click_moving and before.distance_to(player.ground)<0.01:
			click_moving = false
	player.step(delta)
	if is_instance_valid(mentor):
		mentor.step(delta)
	for enemy in enemies:
		_update_enemy(enemy,delta)
	enemies=enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	if auto_attack and stage>=1 and meteor_timer<=0 and attack_cooldown<=0:
		if nearest_enemy(230) != null:
			Mkit.commands().dispatch(GameCommand.create("wf.attack","wf.player","wf.player",{}))
	_update_projectiles(delta)
	impact.advance(delta)
	spells.advance(delta)
	if area=="dungeon" and stage==3: expedition.advance(delta)
	if meteor_timer > 0:
		meteor_timer -= delta
		if meteor_timer <= 0:
			for enemy in enemies:
				if not enemy.health.dead and enemy.ground.distance_to(meteor_target)<125:
					deal_damage(player,enemy,330,"meteor")
			effects.burst(meteor_target,Color("ffbf64"),65,190)
			effects.circle(meteor_target,155,Color("ffc67e"),0.8)
			spells.visual("ultimate_burst",meteor_target,125,10,1.2)
			spells.visual("impact",meteor_target,145,10,1.0)
			screen_shake = 9
			spells.play("ultimate-impact",10)
			impact.play("meteor",meteor_target,5)
			impact.impulse(Vector2(0,1),6.0)
	effects.step(delta)
	screen_shake = move_toward(screen_shake,0,delta*20)
	var focus := player.position+CAMERA_LEAD
	camera.position = camera.position.lerp(focus,1.0-exp(-delta*4))
	camera.offset = (Vector2(sin(elapsed*72),cos(elapsed*65))*screen_shake*0.22+impact.camera_offset).limit_length(8.0)
	autosave_timer += delta
	if autosave_timer>20:
		autosave_timer = 0
		save_profile()

func walkable(at: Vector2, radius: float = 10) -> bool:
	var boundary: Vector2 = City.BOUNDS if area=="city" else Vector2.ONE*LIMIT
	if absf(at.x)>boundary.x-radius or absf(at.y)>boundary.y-radius:
		return false
	if area=="city":
		if not City.inside_city(at,radius): return false
		if ((at-City.POND)/Vector2(1.2,0.9)).length()<55+radius: return false
	elif at.distance_to(Vector2(-255,235))<85+radius:
		return false
	for prop in props:
		if prop.has_method("blocks") and prop.blocks(at,radius): return false
		if prop.radius>0 and at.distance_to(prop.ground)<prop.radius+radius:
			return false
	return true

func move_actor(actor: WFActor, movement: Vector2) -> void:
	# Substeps keep fast dodges from tunneling through trunks or pond edges.
	var count := maxi(1,ceili(movement.length()/5))
	var increment := movement/count
	for i in range(count):
		if walkable(actor.ground+increment):
			actor.ground += increment
		else:
			if walkable(actor.ground+Vector2(increment.x,0)):
				actor.ground.x += increment.x
			if walkable(actor.ground+Vector2(0,increment.y)):
				actor.ground.y += increment.y

func _update_enemy(enemy: WFActor, delta: float) -> void:
	if enemy.health.dead:
		enemy.step(delta)
		if enemy.death_age>=1.25: enemy.queue_free()
		return
	enemy.moving = false
	if expedition.complete or expedition.failed or enemy.call("is_recovering"):
		enemy.step(delta)
		return
	var distance := enemy.ground.distance_to(player.ground)
	if enemy.windup > 0:
		enemy.windup -= delta
		if enemy.windup <= 0:
			enemy.attack_pose = 0.35
			if player.ground.distance_to(enemy.attack_target)<(65 if enemy.elite else 40) and player.invincible<=0:
				deal_damage(enemy,player,32 if enemy.get_meta("boss",false) else (16 if enemy.elite else 8),"physical")
				player.invincible=0.35
				screen_shake = 3
			effects.burst(enemy.attack_target,Color("c0aa73"),8,40)
			enemy.cooldown = 1.25
	elif distance<47 and enemy.cooldown<=0:
		enemy.windup = 0.85
		enemy.attack_target = player.ground
		enemy.face(player.ground-enemy.ground)
	elif distance<(1400 if enemy.get_meta("horde",false) else 270) and distance>36:
		var direction := (player.ground-enemy.ground).normalized()
		# Gentle separation prevents stacked enemies and unreadable telegraphs.
		for other in enemies:
			if other!=enemy and not other.health.dead and other.ground.distance_to(enemy.ground)<28:
				direction += (enemy.ground-other.ground).normalized()*0.5
		move_actor(enemy,direction.normalized()*float(enemy.get_meta("speed",48 if not enemy.elite else 38))*delta)
		enemy.face(direction)
		enemy.moving = true
	enemy.step(delta)

func nearest_enemy(range_limit: float = 250) -> WFActor:
	var result: WFActor
	var distance := range_limit
	for enemy in enemies:
		var d := enemy.ground.distance_to(player.ground)
		if not enemy.health.dead and d<distance:
			distance = d
			result = enemy
	return result

func perform_attack() -> bool:
	if expedition.complete or expedition.failed: return false
	if area!="dungeon" or paused or not dialogue.is_empty() or attack_cooldown>0 or meteor_timer>0:
		if area=="dungeon" and not paused and dialogue.is_empty() and meteor_timer<=0 and attack_cooldown>0 and attack_cooldown<=0.12:
			impact.basic_buffer = 0.12
		return false
	if player.call("is_recovering") or not impact.casts.is_empty(): return false
	var target := nearest_enemy(270)
	if target == null:
		return false
	var direction := (target.ground-player.ground).normalized()
	player.face(direction)
	attack_cooldown = 0.7
	impact.queue_basic(direction)
	return true

func launch_bolt(direction: Vector2, damage: float, element: String) -> void:
	projectiles.append({"at":player.ground,"direction":direction,"speed":330.0,"life":1.5,"damage":damage,"element":element,"color":Color("ffaa4f") if element=="fire" else Color("d7dfb0")})
	var target := nearest_enemy(500)
	projectiles[-1].muzzle=player.staff_tip_offset()
	projectiles[-1].age=0.0
	projectiles[-1].flight=clampf(player.ground.distance_to(target.ground)/330.0,0.08,0.7) if target!=null else 0.25

func _update_projectiles(delta: float) -> void:
	for bolt in projectiles:
		var old: Vector2 = bolt.at
		bolt.age=float(bolt.get("age",0))+delta
		bolt.at += bolt.direction*bolt.speed*delta
		bolt.life -= delta
		for enemy in enemies:
			if enemy.health.dead:
				continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.ground,old,bolt.at)
			if closest.distance_to(enemy.ground)<18:
				deal_damage(player,enemy,bolt.damage,bolt.element)
				if bolt.element=="fire":
					effects.circle(enemy.ground,45,Color("ffc577"))
					for other in enemies:
						if other!=enemy and not other.health.dead and other.ground.distance_to(enemy.ground)<45:
							deal_damage(player,other,bolt.damage*0.5,"fire")
				bolt.life = 0
				break
	projectiles = projectiles.filter(func(b): return b.life>0)

func deal_damage(source: WFActor, target: WFActor, amount: float, element: String) -> DamageResult:
	var request := DamageRequest.new()
	request.source = source
	request.target = target
	# Practice-only power growth keeps the escalating elite a damage-number demo.
	request.base_amount = amount * (pow(1.5,wave-1) if stage==3 and source==player else 1.0)
	request.element_type = element
	request.can_crit = source==player and element!="meteor"
	request.can_evade = false
	request.can_block = false
	var result := Mkit.combat().resolve(request)
	if target.health.dead:
		return result
	target.set_meta("rage_eligible_kill",source==player and element!="meteor")
	target.health.apply_damage(result)
	if source==player and element!="meteor" and rage_hit_timer<=0:
		rage = minf(100,rage+2*(1.0+float(spells.modifiers.get("rage",0))))
		rage_hit_timer = 0.5
	return result

func hit_feedback(actor: WFActor, result: DamageResult) -> void:
	impact.react(actor,result)

func cast_skill(index: int) -> bool:
	if index<0 or index>4 or not expedition.card_choices.is_empty() or expedition.complete or expedition.failed: return false
	if area!="dungeon":
		toast("城内是安全区域；与梅尔交谈后传送到副本。","The city is safe. Speak to Mel to enter an instance.")
		return false
	if paused or not dialogue.is_empty() or meteor_timer>0:
		return false
	if stage<3:
		toast("完成帽子试炼后，开放四元素试演。","Complete the hat trial to unlock the elemental practice.")
		return false
	if skill_cooldowns[index]>0:
		return false
	if player.call("is_recovering"): return false
	if index<4 and not impact.casts.is_empty(): return false
	var target := nearest_enemy(430)
	if target==null:
		toast("附近没有目标。往副本前方的空地走走。","No target nearby. Head deeper into the instance.")
		return false
	if index<4:
		impact.queue_spell(index,target)
	else:
			if rage<100:
				toast("怒气尚未蓄满。击中或击败敌人继续收集。","Build more rage by hitting and defeating enemies.")
				return false
			rage = 0
			impact.casts.clear()
			meteor_target = target.ground
			meteor_timer = 1.3
			var falling: Node2D=spells.visual("ultimate_fall",meteor_target,125,10,1.3)
			falling.launch_at=0.25
			player.invincible = 1.5
			player.moving = false
			skill_cooldowns[4] = 2
			toast("结印 · 天火降临","SEAL OF THE FALLING SUN",1.4)
			spells.start_ultimate_audio()
	return true

func _enemy_died(enemy: WFActor) -> void:
	if enemy.get_meta("death_awarded",false): return
	enemy.set_meta("death_awarded",true)
	enemy.death_age=0
	enemy.moving=false
	enemy.windup = 0
	kills += 1
	if enemy.get_meta("rage_eligible_kill",true):
		rage = minf(100,rage+(8 if enemy.elite else 2)*(1.0+float(spells.modifiers.get("rage",0))))
	impact.play("death",enemy.ground,3,-3)
	if stage==1:
		stage = 2
		Mkit.events().emit_domain_event(DomainEvent.create("wf.hat_collected","wf.player",enemy.get_entity_id(),{"amount":1}))
		toast("获得：哥布林的帽子 ×1 · 按 E / B 回城交任务","Goblin's Hat ×1 · Press E / B to return and turn in",8)
		play_sound("quest")
		save_profile()

func all_enemies_dead() -> bool:
	if enemies.is_empty():
		return false
	for enemy in enemies:
		if not enemy.health.dead:
			return false
	return true

func interact() -> void:
	if travel_open:
		close_travel()
		return
	if paused:
		paused = false
		return
	if not dialogue.is_empty():
		dialogue_index += 1
		if dialogue_index>=dialogue.size():
			dialogue.clear()
			_finish_dialogue()
		return
	if area=="dungeon":
		if stage==2 or player.ground.distance_to(DUNGEON_START)<70:
			return_to_city()
		else:
			toast("按 B 可退出当前副本，返回晨铃城。","Press B to leave this instance and return to Bellwake.")
		return
	if City.station_near(player.ground,75)>=0:
		open_travel()
		return
	if player.ground.distance_to(mentor.ground)>65:
		toast("靠近传送石可按 E 选择地点；梅尔在召唤广场。","Press E near a waystone to travel. Mel is at Summoning Square.")
		return
	player.face(mentor.ground-player.ground)
	mentor.face(player.ground-mentor.ground)
	dialogue_index = 0
	match stage:
		0:
			dialogue = [["城外的哥布林抢走了商队的面包，还开始收过路费。\n带回它的帽子，就算通过你的就职试炼。","A goblin beyond the city stole the caravan's bread and now demands tolls.\nBring back its hat to complete your initiation trial."],["拿好这根法杖。用普攻就能完成，不需要先学魔法。\n看清它的动作，离开红圈，再还击。","Take this staff. Basic attacks are enough; no spells are needed.\nWatch its movements, step out of the red circle, then strike."],["准备好了？我现在送你进入独立的哥布林副本。\n拿到帽子后按 E 或 B 回城，我在这里等你。","Ready? I will now send you into a separate goblin instance.\nOnce you have the hat, press E or B to return. I'll be here."]]
			dialogue_action = "accept"
		1:
			dialogue = [["试炼还没结束。我送你重新进入哥布林副本。\n城里不会出现敌人，你可以随时回来休息。","Your trial is still open. I can send you back into the goblin instance.\nThe city has no enemies; return whenever you need to rest."]]
			dialogue_action = "resume"
		2:
			dialogue = [["帽子收到了。你已经懂得如何保护自己了。\n欢迎踏上法师的道路。","Hat received. You've learned to protect yourself.\nWelcome to the path of the mage."],["四元素试炼已经向你开放。\n去熟悉每种元素，也练习掌控怒气。","The elemental trial is now open to you.\nLearn each element and practice channeling your rage."],["先在城里休息。想练习时再与我交谈，\n我会把你传送到独立的元素试炼副本。","Rest in the city. Speak to me again when you want to practice,\nand I will send you into a separate elemental trial instance."]]
			dialogue_action = "turn_in"
		_:
			dialogue = [["地下灵堂的钟声，最近总在没有风的时候响起。\n不过今天，先到元素试炼副本熟悉这四种力量吧。","The mortuary bells have been ringing without wind.\nFor today, the elemental instance will help you learn these powers."],["战斗积攒怒气，满 100 时按 Q 结印召唤火陨石。\n现在开始传送；想休息时，按 B 返回安全的城内。","Build 100 rage in battle, then Q summons a fire meteor.\nTeleporting now. Press B whenever you want to return to the safe city."]]
			dialogue_action = "practice"
	play_sound("bell")

func _finish_dialogue() -> void:
	match dialogue_action:
		"arrival":
			intro_seen = true
			toast("在晨铃城苏醒 · 准备好后与梅尔交谈","Awakened in Bellwake · Speak to Mel when ready",6)
		"accept":
			stage = 1
			Mkit.quest().accept_quest(QUEST_ID,GameplayContext.from_nodes(player))
			enter_dungeon()
		"turn_in":
			var context := GameplayContext.from_nodes(player)
			Mkit.quest().complete_quest(QUEST_ID,context)
			Mkit.quest().turn_in_quest(QUEST_ID,context)
			stage = 3
			player.health.heal(120)
			toast("就职完成 · 再与梅尔交谈，可进入元素试炼副本","Initiation complete · Speak to Mel to enter elemental practice",6)
			play_sound("quest")
		"resume", "practice":
			enter_dungeon()
	dialogue_action = ""
	save_profile()

func _player_died(_entity: Node) -> void:
	impact.reset()
	# Safe retry for this art sample: preserve the quest, restore at the mentor.
	player.health.revive(1.0)
	player.ground = DUNGEON_START if area=="dungeon" else START
	player.invincible = 3
	projectiles.clear()
	meteor_timer = 0
	click_moving = false
	for enemy in enemies:
		enemy.ground = enemy.spawn_ground
		enemy.windup = 0
		enemy.cooldown = 2
	return_to_city.call_deferred()
	save_profile()

func dodge() -> void:
	if dodge_cooldown>0 or meteor_timer>0:
		return
	dodge_direction = last_direction
	impact.casts.clear()
	player.call("reset_performance")
	dodge_timer = 0.2
	dodge_cooldown = 1.3
	player.invincible = 0.3
	effects.circle(player.ground,25,Color("b9d9c0"),0.3)
	impact.play("dodge",player.ground,1,-5)

func _unhandled_input(event: InputEvent) -> void:
	if not expedition.card_choices.is_empty():
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_3:
			expedition.choose(event.physical_keycode-KEY_1)
		get_viewport().set_input_as_handled()
		return
	if travel_open:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode in [KEY_ESCAPE,KEY_E]:
				close_travel()
			elif event.physical_keycode==KEY_L:
				toggle_language()
			elif event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_5:
				travel_to(event.physical_keycode-KEY_1)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_B:
			return_to_city()
			get_viewport().set_input_as_handled()
			return
		match event.physical_keycode:
			KEY_L: toggle_language()
			KEY_M: toggle_sound()
			KEY_ESCAPE: toggle_pause()
			KEY_E: interact()
			KEY_SPACE:
				if not dialogue.is_empty():
					interact()
				elif not paused:
					Mkit.commands().dispatch(GameCommand.create("wf.attack","wf.player","wf.player",{}))
			KEY_F:
				auto_attack = not auto_attack
				save_profile()
		if paused or not dialogue.is_empty():
			return
		match event.physical_keycode:
			KEY_1: cast_skill(0)
			KEY_2: cast_skill(1)
			KEY_3: cast_skill(2)
			KEY_4: cast_skill(3)
			KEY_Q: cast_skill(4)
			KEY_SHIFT: dodge()
	if event is InputEventMouseButton and event.pressed and not paused and dialogue.is_empty():
		match event.button_index:
			MOUSE_BUTTON_LEFT: perform_attack()
			MOUSE_BUTTON_RIGHT:
				request_walk(WFIso.unproject(get_global_mouse_position()))
			MOUSE_BUTTON_WHEEL_UP: camera.zoom = Vector2.ONE*minf(camera.zoom.x+0.08,1.55)
			MOUSE_BUTTON_WHEEL_DOWN: camera.zoom = Vector2.ONE*maxf(camera.zoom.x-0.08,0.8)

func request_walk(destination: Vector2) -> void:
	click_path.clear()
	click_moving = false
	if area=="city":
		click_path = city_navigation.route(player.ground,destination)
		if click_path.is_empty():
			toast("这里无法到达，请点击街道或空地。","Cannot reach that spot. Click a street or open ground.",2)
			return
		click_destination = click_path[0]
		click_path.remove_at(0)
	else: click_destination = destination
	click_moving = true

func say(zh: String, en: String) -> String:
	return zh if language=="zh" else en

func toast(zh: String, en: String, duration: float = 3.5) -> void:
	toast_zh = zh
	toast_en = en
	toast_timer = duration

func toggle_language() -> void:
	language = "en" if language=="zh" else "zh"
	save_profile()

func toggle_pause() -> void:
	if travel_open:
		close_travel()
		return
	paused = not paused
	if paused:
		save_profile()

func toggle_sound() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0,muted)
	save_profile()

func confirm_restart() -> void:
	if not restart_armed:
		restart_armed = true
		toast("再次点击重来按钮，将重置当前游戏进度。","Click restart again to reset your game progress.",5)
		get_tree().create_timer(5).timeout.connect(func(): restart_armed=false)
		return
	stage = 0
	intro_seen = false
	rage = 0
	kills = 0
	wave = 1
	Mkit.quest().log = QuestLog.new()
	save_profile()
	get_tree().reload_current_scene()

func save_profile() -> void:
	if simulation or capture_mode or review_mode:
		return
	last_save_success = Mkit.save().save_game(get_tree().root)
	if not last_save_success:
		toast("进度保存失败；请留意可用磁盘空间。","Progress could not be saved. Please check available disk space.",5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_profile()
		get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(ambient):
		ambient.release_streams()
	if Mkit.commands()!=null:
		Mkit.commands().unregister_receiver("wf.player")

func _build_audio() -> void:
	AudioServer.set_bus_mute(0,muted)
	ambient = MusicDirector.new()
	ambient.world = self
	add_child(ambient)
	if not simulation:
		ambient.start(area)
	for i in range(8):
		var sound := AudioStreamPlayer.new()
		sound.volume_db = -15
		add_child(sound)
		sound_nodes.append(sound)

func play_sound(kind: String) -> void:
	if simulation or muted:
		return
	for sound in sound_nodes:
		if not sound.playing:
			sound.stream = load("res://game/whispering_forest/assets/"+kind+".wav")
			sound.pitch_scale = randf_range(0.96,1.04)
			sound.play()
			return

func _smoke_test() -> void:
	# This is an end-to-end gameplay verification, not a mirror of each function.
	var failures: Array[String] = []
	var check := func(ok: bool, message: String):
		if not ok:
			failures.append(message)
	check.call(WFIso.unproject(WFIso.project(Vector2(72,-34))).distance_to(Vector2(72,-34))<0.01,"isometric roundtrip")
	check.call(not walkable(Vector2(0,-320)),"guild foundation collision")
	check.call(not walkable(City.POND),"garden pond collision")
	check.call(walkable(START),"spawn is walkable")
	for station in City.STATIONS:
		check.call(not city_navigation.route(START,station.landing).is_empty(),"walkable route from arrival to "+station.id)
	for b in City.BUILDINGS:
		var door := City.doorstep(b)
		check.call(not city_navigation.route(START,door).is_empty(),"reachable frontage: "+b.id)
		for street in City.STREETS:
			check.call(not City.footprint(b).intersects(street),"street stays outside foundation: "+b.id)
	for side in [-1,1]:
		check.call(not city_navigation.route(START,Vector2(1060*side,40)).is_empty(),"continuous route across gate and bridge")
		check.call(not city_navigation.route(START,Vector2(1180*side,40)).is_empty(),"bridge reaches a walkable outer landing")
		check.call(not walkable(Vector2(900*side,260)),"solid curtain wall away from gates")
		check.call(not walkable(Vector2(980*side,200)),"moat cannot be crossed away from bridge")
	check.call(city_navigation.route(START,Vector2(0,-320)).is_empty(),"navigation rejects building interiors")
	check.call(area=="city" and enemies.is_empty(),"new game starts in a safe city")
	_begin_arrival()
	check.call(not dialogue.is_empty() and area=="city","summoning introduction takes place inside the city")
	while not dialogue.is_empty():
		interact()
	check.call(intro_seen and stage==0,"arrival does not silently accept the trial")
	check.call(not cast_skill(3) and enemies.is_empty(),"city cannot run combat skills")
	# Walk input covers cardinal and diagonal facings, plus real frame changes.
	var facings: Dictionary = {}
	var walk_frames: Dictionary = {}
	var fixed_pivot := player.sprite.offset
	player.last_ground = player.ground
	for i in range(8):
		var angle := i*PI/4
		var screen_direction := Vector2(-sin(angle),cos(angle))
		var ground_direction := WFIso.unproject(screen_direction).normalized()
		player.face(ground_direction)
		facings[player.facing] = true
		check.call(player.facing==i,"eight-direction input faces its expected screen heading")
		player.moving = true
		player.ground += ground_direction*8.76
		player.step(0.06)
		walk_frames[player.animation_frame] = true
		check.call(player.animation_state=="walk" and not player.sprite.flip_h,"walking uses its own directional animation without mirroring")
		check.call(player.sprite.offset==fixed_pivot,"animation keeps a shared foot pivot")
	check.call(facings.size()==8,"all eight facings are reachable")
	# The current character has a run/start transition and a separately timed
	# walking clip. Sample a complete slow walk instead of assuming that eight
	# arbitrary running ticks must equal the old eight-frame walking cycle.
	walk_frames.clear()
	for i in range(160):
		player.ground+=Vector2(1,0)
		player.step(0.02)
		if player.get("rendered_action")=="walk": walk_frames[player.animation_frame]=true
	check.call(walk_frames.size()==player.clips.walk[0].size(),"all frames of the current walking clip are reachable")
	player.moving = false
	player.step(0.06)
	check.call(player.animation_state=="idle","stopping movement returns to the breathing idle")
	player.moving = true
	player.step(0.06)
	check.call(player.animation_state=="idle","blocked movement does not play a walk cycle in place")
	player.moving = false
	player.ground = START
	check.call(waystones.size()==5,"five physical waystones are placed in the city")
	player.ground = City.STATIONS[0].landing
	await _test_key(KEY_E)
	check.call(travel_open,"E at a waystone opens destination selection")
	var before_travel := player.ground
	step(0.1)
	check.call(player.ground==before_travel,"destination selection holds player movement")
	await _test_click(Vector2(hud.size.x/2,hud.size.y/2-102+4*57))
	check.call(not travel_open and player.ground==City.STATIONS[4].landing,"pointer destination button travels to the city gate")
	check.call(area=="city" and stage==0 and enemies.is_empty(),"in-city travel cannot accept quests or create enemies")
	for i in range(City.STATIONS.size()):
		await _test_key(KEY_E)
		await _test_key(KEY_1+i)
		check.call(player.ground==City.STATIONS[i].landing and walkable(player.ground),"waystone %d has a reachable clear arrival point" % i)
	await _test_key(KEY_E)
	await _test_key(KEY_ESCAPE)
	check.call(not travel_open and not paused,"Escape dismisses the waystone menu without opening pause")
	player.ground = START
	request_walk(City.STATIONS[2].landing)
	for i in range(1800):
		if not click_moving: break
		step(1.0/60)
	check.call(not click_moving and player.ground.distance_to(City.STATIONS[2].landing)<8,"click navigation actually walks around buildings to its destination")
	player.ground = START
	player.position = WFIso.project(START)
	# Feed events through the viewport, exercising GUI routing and the input path.
	var previous_language := language
	await _test_click(Vector2(hud.size.x-179,43))
	check.call(language!=previous_language,"language button responds to a pointer click")
	await _test_key(KEY_L)
	check.call(language==previous_language,"L switches the language back")
	await _test_key(KEY_ESCAPE)
	check.call(paused,"Escape opens help and pauses the simulation")
	await _test_key(KEY_ESCAPE)
	check.call(not paused,"Escape resumes the simulation")
	var movement_start := player.ground
	var move_event := InputEventKey.new()
	move_event.keycode = KEY_D
	move_event.physical_keycode = KEY_D
	move_event.pressed = true
	Input.parse_input_event(move_event)
	await get_tree().process_frame
	step(0.1)
	check.call(WFIso.project(player.ground-movement_start).x>10,"D input moves right in the projected world")
	move_event.pressed = false
	Input.parse_input_event(move_event)
	await get_tree().process_frame
	for prop in props:
		if prop.has_method("refresh") and prop.asset=="linden":
			player.ground = prop.ground+Vector2(-30,-30)
			player.position = WFIso.project(player.ground)
			prop._process(1)
			check.call(is_equal_approx(prop.sprite.modulate.a,1.0),"canopy remains opaque when the player walks behind it")
			break
	var guild_foot := City.footprint(City.BUILDINGS[0])
	player.ground = Vector2(guild_foot.end.x+25,guild_foot.get_center().y)
	move_actor(player,Vector2(-400,0))
	check.call(player.ground.x>=guild_foot.end.x,"fast movement cannot tunnel through guild foundation")
	player.ground = mentor.ground+Vector2(30,0)
	await _test_key(KEY_E)
	check.call(not dialogue.is_empty(),"E input opens the mentor dialogue")
	while not dialogue.is_empty():
		interact()
	check.call(stage==1 and area=="dungeon" and mentor==null and enemies.size()==1,"accept Q101 teleports into a separate goblin instance")
	open_travel()
	check.call(not travel_open and waystones.is_empty(),"city travel is unavailable inside quest instances")
	await _test_click(Vector2(hud.size.x-291,43))
	check.call(area=="city" and stage==1 and enemies.is_empty(),"return button exits the instance without spawning enemies in the city")
	player.ground = mentor.ground+Vector2(30,0)
	interact()
	while not dialogue.is_empty():
		interact()
	check.call(area=="dungeon" and enemies.size()==1,"an unfinished quest can re-enter a fresh instance")
	check.call(is_equal_approx(enemies[0].health.current_hp,60),"trial goblin HP 60")
	check.call(not cast_skill(0),"trial requires no unlocked skill")
	player.stats_component.set_base_stat("crit_chance",0)
	player.ground = Vector2(50,85)
	var target := enemies[0]
	for i in range(5):
		attack_cooldown = 0
		check.call(Mkit.commands().dispatch(GameCommand.create("wf.attack","wf.player","wf.player",{})),"command-dispatched staff attack")
		impact.advance(0.18)
		_update_projectiles(0.2)
		target.step(0.4)
	check.call(stage==2 and target.health.dead,"five 12-damage attacks finish the zero-skill trial")
	check.call(Mkit.quest().is_quest_complete(QUEST_ID),"hat domain event advances the mkit quest")
	await _test_key(KEY_E)
	check.call(area=="city" and stage==2 and enemies.is_empty(),"E returns with the collected hat; city remains safe")
	player.ground = mentor.ground+Vector2(30,0)
	interact()
	while not dialogue.is_empty():
		interact()
	check.call(stage==3 and area=="city" and enemies.is_empty(),"turn-in unlocks practice but does not spawn city enemies")
	check.call(Mkit.quest().get_state(QUEST_ID).status==QuestState.STATUS_TURNED_IN,"quest turned in once")
	interact()
	while not dialogue.is_empty():
		interact()
	expedition.advance(0.76)
	check.call(area=="dungeon" and enemies.size()>=12,"practice launches an independent continuous-horde instance")
	player.ground = enemies[0].ground-Vector2(35,0)
	player.stats_component.set_base_stat("crit_chance",0)
	for enemy in enemies:
		enemy.stats_component.set_base_stat("max_hp",300)
		enemy.health.current_hp=300
	var fire_target := nearest_enemy(430)
	check.call(cast_skill(0),"fire explosion cast")
	check.call(not cast_skill(0),"fire cooldown prevents duplicate cast")
	impact.advance(0.19)
	spells.advance(0.37)
	check.call(fire_target!=null and fire_target.health.current_hp<300,"fire explosion damages the selected enemy at ignition")
	check.call(cast_skill(1),"wind skill casts")
	impact.advance(0.18)
	check.call(cast_skill(2),"earth skill casts")
	impact.advance(0.18)
	player.health.current_hp = 40
	check.call(cast_skill(3) and player.health.current_hp==40,"ice attacks enemies rather than healing the caster")
	spells.reset()
	rage = 99
	check.call(not cast_skill(4),"ultimate unavailable below full rage")
	rage = 100
	check.call(cast_skill(4) and rage==0,"ultimate spends full rage")
	auto_attack = false
	step(1.31)
	check.call(meteor_timer<=0,"meteor resolves after its seal windup")
	check.call(rage==0,"meteor kills cannot refill ultimate rage")
	var snapshot := profile.to_save_data()
	language = "en"
	profile.from_save_data(snapshot)
	check.call(language==snapshot.language,"profile restores language")
	Mkit.save().save_path = "/tmp/whispering_forest_smoke_test.json"
	check.call(Mkit.save().save_game(get_tree().root),"mkit atomic save")
	stage = 0
	check.call(Mkit.save().load_game(get_tree().root) and stage==3,"mkit save/reload restores progress")
	DirAccess.remove_absolute(Mkit.save().save_path)
	Mkit.save().save_path = PROFILE_PATH
	await _test_key(KEY_B)
	_spawn_wave()
	check.call(area=="city" and enemies.is_empty(),"returning unloads all combat entities; city rejects wave spawns")
	profile.from_save_data({"version":1,"stage":3,"language":"en","rage":64,"wave":5})
	check.call(intro_seen and stage==3 and wave==5 and rage==64,"v1 saves retain practice progress in the new city hub")
	if failures.is_empty():
		print("WF_SMOKE_OK: planned city / frontage routes / wall and bridge topology / click navigation, eight-direction walking/idle/foot pivots, summoned city, 5 waystones, safe city, quest teleport, return button/re-entry, Q101 turn-in, separate practice, collision, cooldown, rage, meteor, save/reload, v1 migration")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("WF_SMOKE_FAILED: "+failure)
		get_tree().quit(1)

func _test_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	await get_tree().process_frame
	event.pressed = false
	get_viewport().push_input(event)
	await get_tree().process_frame

func _test_click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	get_viewport().push_input(motion,true)
	await get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	await get_tree().process_frame
	event.pressed = false
	get_viewport().push_input(event,true)
	await get_tree().process_frame

func _capture() -> void:
	language = capture_language
	auto_attack = false
	if capture_dungeon:
		stage = 3
		enter_dungeon()
		player.ground = Vector2(-20,70)
		rage = 76
	else:
		stage = 0
		arrival_glow = 3
		if capture_travel or capture_station>=0:
			player.ground = City.STATIONS[0].landing
			player.position = WFIso.project(player.ground)
			open_travel()
			if capture_station>=0:
				travel_to(capture_station)
	player.face(Vector2(1,0))
	toast_timer = 0
	for enemy in enemies:
		enemy.cooldown = 99
	await get_tree().create_timer(0.7).timeout
	paused = false
	if capture_dungeon:
		launch_bolt((enemies[0].ground-player.ground).normalized(),45,"fire")
	await get_tree().create_timer(0.11).timeout
	if capture_dialogue and area=="city":
		_begin_arrival()
	set_process(false)
	if capture_overview:
		hud.hide()
		camera.zoom = Vector2.ONE*0.33*(get_viewport_rect().size.x/1280.0)
		camera.position = Vector2(0,-95)
		camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(capture_path)
	print("WF_CAPTURE: %s error=%d" % [capture_path,error])
	get_tree().quit(0 if error==OK else 1)

func _walk_showcase() -> void:
	auto_attack = false
	stage = 0
	intro_seen = true
	player.ground = Vector2(-160,-60)
	player.last_ground = player.ground
	player.position = WFIso.project(player.ground)
	camera.position = player.position+CAMERA_LEAD
	toast("八方向行走 · 移动、停步与待机","Eight-direction walk · movement, stopping and idle",3)
	await get_tree().create_timer(0.6).timeout
	for direction in [6,7,0,1,2,3,4,5]:
		var a: float = direction*PI/4
		showcase_direction = WFIso.unproject(Vector2(-sin(a),cos(a))).normalized()
		await get_tree().create_timer(0.65).timeout
		showcase_direction = Vector2.ZERO
		await get_tree().create_timer(0.25).timeout
	await get_tree().create_timer(2.4).timeout
	print("WF_WALK_SHOWCASE_OK: eight-direction movement and stops in the actual city")
	await _finish_recording()

func _showcase() -> void:
	# A reproducible recording, with pre-filled rage for the ultimate art preview.
	auto_attack = false
	toast_timer = 0
	arrival_glow = 2.5
	await get_tree().create_timer(2.5).timeout
	player.ground = City.STATIONS[0].landing
	player.position = WFIso.project(player.ground)
	open_travel()
	await get_tree().create_timer(1.4).timeout
	travel_to(4)
	await get_tree().create_timer(2.0).timeout
	stage = 3
	enter_dungeon()
	player.ground = Vector2(-50,65)
	player.invincible = 30
	for enemy in enemies:
		enemy.cooldown = 3
	await get_tree().create_timer(1.0).timeout
	showcase_direction = Vector2(1,0)
	await get_tree().create_timer(0.6).timeout
	showcase_direction = Vector2.ZERO
	cast_skill(0)
	await get_tree().create_timer(1.5).timeout
	cast_skill(1)
	await get_tree().create_timer(1.5).timeout
	cast_skill(0)
	await get_tree().create_timer(1.4).timeout
	player.health.current_hp = 75
	cast_skill(3)
	await get_tree().create_timer(1.0).timeout
	rage = 100
	cast_skill(4)
	await get_tree().create_timer(2.5).timeout
	cast_skill(2)
	await get_tree().create_timer(2.0).timeout
	print("WF_SHOWCASE_OK")
	await _finish_recording()

func _finish_recording() -> void:
	# Movie capture needs an audio mix tick to release active WAV playbacks.
	ambient.stop()
	for sound in sound_nodes:
		sound.stop()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _city_tour() -> void:
	# Real map, navigation and waystones; recording mode cannot alter saves.
	auto_attack = false
	intro_seen = true
	dialogue.clear()
	stage = 0
	capture_overview = true
	hud.hide()
	set_process(false)
	camera.zoom = Vector2.ONE*0.33*(get_viewport_rect().size.x/1280.0)
	camera.position = Vector2(0,-95)
	camera.force_update_scroll()
	await get_tree().create_timer(3).timeout
	capture_overview = false
	hud.show()
	camera.zoom = Vector2.ONE
	set_process(true)
	toast("召唤广场 · 北侧钟楼公会","Summoning Square · Guild to the north",4)
	request_walk(City.STATIONS[1].landing)
	await _wait_for_walk()
	await get_tree().create_timer(1.5).timeout
	open_travel()
	travel_to(2)
	toast("工匠街 · 铁匠铺 / 药草店 / 晨间市集","Artisans' Market · Smithy / Apothecary / Market",4)
	await get_tree().create_timer(3).timeout
	open_travel()
	travel_to(3)
	toast("南侧庭院 · 伙伴之家与居民花园","Southern courtyard · Companion lodge and gardens",4)
	await get_tree().create_timer(3).timeout
	open_travel()
	travel_to(4)
	toast("东城门 · 穿过门洞，走上护城桥","East Gate · Walk through the arch and onto the bridge",7)
	await get_tree().create_timer(1).timeout
	request_walk(Vector2(1060,40))
	await _wait_for_walk()
	await get_tree().create_timer(2).timeout
	print("WF_CITY_TOUR_OK: districts, waystone travel, gate arch and bridge walk")
	await _finish_recording()

func _wait_for_walk() -> void:
	for i in range(140):
		if not click_moving: return
		await get_tree().create_timer(0.1).timeout
	push_error("WF_CITY_TOUR_WALK_TIMEOUT")
