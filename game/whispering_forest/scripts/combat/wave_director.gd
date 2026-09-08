extends Node

const Tuning = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const WAVE_SECONDS := 180.0
const TOTAL_SECONDS := 900.0
const ACTIVE_LIMIT := 96
var world: Node
var time := 0.0
var spawn_clock := 0.0
var active := false
var complete := false
var failed := false
var boss: WFActor
var spawned := 0
var card_choices: Array[Dictionary] = []
var choices_taken := 0
var pending_spawns: Array[Dictionary] = []
var rng:=RandomNumberGenerator.new()

func start() -> void:
	reset()
	active=true
	world.wave=1
	rng.randomize()
	queue_pack(12)
	world.toast("远征开始 · 5 波 × 3 分钟 · 第 5 波迎战首领","Expedition · five 3-minute waves · boss in wave 5",5)

func reset() -> void:
	active=false; complete=false; failed=false; time=0; spawn_clock=0; spawned=0
	choices_taken=0; card_choices.clear(); pending_spawns.clear(); boss=null
	if is_instance_valid(world.spells): world.spells.modifiers.clear()
	if is_instance_valid(world.player):
		world.player.stats_component.set_base_stat("max_hp",120)
		world.player.stats_component.set_base_stat("crit_chance",0.1)

func advance(delta: float) -> void:
	if not active or not card_choices.is_empty(): return
	time=minf(TOTAL_SECONDS,time+delta)
	var next_wave:=mini(5,1+int(time/WAVE_SECONDS))
	if next_wave!=world.wave:
		world.wave=next_wave
		world.player.health.heal(25)
		if next_wave==5: spawn_boss()
		roll_cards()
		world.toast("第 %d 波 · 选择一张强化卡" % next_wave,"Wave %d · choose an upgrade" % next_wave,4)
		return
	for event in pending_spawns:
		event.delay-=delta
		if event.delay<=0: spawn_enemy(event.at)
	pending_spawns=pending_spawns.filter(func(e): return e.delay>0)
	spawn_clock-=delta
	if spawn_clock<=0:
		queue_pack([5,7,9,12,6][world.wave-1])
		spawn_clock=[3.4,3.0,2.6,2.3,3.5][world.wave-1]
	if world.wave==5 and is_instance_valid(boss) and boss.health.dead:
		finish(true)
	elif time>=TOTAL_SECONDS:
		finish(false)

func alive_count() -> int:
	var count:=0
	for enemy in world.enemies:
		if not enemy.health.dead: count+=1
	return count

func queue_pack(count: int) -> void:
	count=mini(count,ACTIVE_LIMIT-alive_count()-pending_spawns.size())
	for i in range(maxi(count,0)):
		var at:=Vector2.ZERO
		var found:=false
		for attempt in range(28):
			# A ring around the traveler keeps the pressure moving with the camera.
			var angle:=rng.randf()*TAU
			at=world.player.ground+Vector2.from_angle(angle)*rng.randf_range(300,420)
			if world.walkable(at,14) and at.distance_to(world.player.ground)>260:
				found=true; break
		if not found: continue
		world.spells.visual("spawn",at,20,1,0.75)
		pending_spawns.append({"at":at,"delay":0.75})

func spawn_enemy(at: Vector2) -> WFActor:
	var elite: bool=world.wave>=2 and spawned%17==16
	var hp:=40.0*pow(1.6,world.wave-1)*(3.0 if elite else 1.0)
	var enemy: WFActor=world._actor("goblin",at,hp,elite)
	spawned+=1
	enemy.name="Horde_%d" % spawned
	enemy.set_meta("horde",true)
	enemy.set_meta("speed",[45.0,53.0,60.0,67.0,55.0][world.wave-1]*(1.12 if spawned%3==0 else 1.0))
	enemy.health.died.connect(func(_actor): world._enemy_died(enemy))
	world.enemies.append(enemy)
	return enemy

func spawn_boss() -> void:
	var at: Vector2=world.player.ground+Vector2(150,-180)
	if not world.walkable(at,24): at=Vector2.ZERO
	boss=spawn_enemy(at)
	boss.set_meta("boss",true)
	boss.set_meta("speed",43.0)
	boss.elite=true
	boss.body_height=118
	boss.sprite.scale=Vector2.ONE*118.0/216.0
	# Chapter parameter is separate from wave number. Later content can supply it.
	var hp:=5000.0*pow(2.4,maxi(0,int(world.get_meta("expedition_tier",1))-1))
	boss.stats_component.set_base_stat("max_hp",hp)
	boss.health.current_hp=hp
	boss.name="GatebreakerBoss"
	world.spells.visual("spawn",at,80,10,1.8)
	boss.cooldown=2.0

func finish(won: bool) -> void:
	active=false; complete=won; failed=not won
	pending_spawns.clear()
	world.spells.reset()
	world.projectiles.clear()
	if world.get("impact")!=null: world.impact.casts.clear()
	for enemy in world.enemies:
		enemy.moving=false; enemy.windup=0
	world.toast("远征完成 · 首领已被击败 · B 返回晨铃城" if won else "远征结束 · 时间已到 · B 回城后可重新挑战","Expedition cleared · Boss defeated · B returns to Bellwake" if won else "Time expired · B returns to the city for another attempt",60)

func roll_cards() -> void:
	card_choices.clear()
	var pool:=range(Tuning.CARDS.size())
	for i in range(3):
		var slot:=rng.randi_range(0,pool.size()-1)
		var data: Array=Tuning.CARDS[pool[slot]]
		pool.remove_at(slot)
		var roll:=rng.randf()
		var rarity:=0 if roll<0.68 else (1 if roll<0.92 else 2)
		card_choices.append({"id":data[0],"zh":data[1],"en":data[2],"rarity":rarity,"value":data[3][rarity]})

func choose(index: int) -> void:
	if index<0 or index>=card_choices.size(): return
	var card: Dictionary=card_choices[index]
	var mods: Dictionary=world.spells.modifiers
	mods[card.id]=float(mods.get(card.id,0))+float(card.value)
	if card.id=="health":
		var extra:=120.0*float(card.value)
		world.player.stats_component.set_base_stat("max_hp",world.player.health.get_max_hp()+extra)
		world.player.health.heal(extra)
	if card.id=="crit": world.player.stats_component.set_base_stat("crit_chance",minf(0.8,0.1+float(mods.crit)))
	choices_taken+=1
	card_choices.clear()
	world.toast("强化已生效："+str(card.zh),"Upgrade applied: "+str(card.en),3)

func timer_text() -> String:
	var seconds:=int(maxf(0,WAVE_SECONDS-fmod(time,WAVE_SECONDS)))
	return "%02d:%02d" % [int(seconds/60),seconds%60]
