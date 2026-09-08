extends Saveable

var world: Node

func _init() -> void:
	save_id = "whispering_forest.sample"
	save_scope = "whispering_forest"

func to_save_data() -> Dictionary:
	return {"version":3,"stage":world.stage,"intro_seen":world.intro_seen,"language":world.language,"rage":world.rage,"kills":world.kills,"muted":world.muted,"auto_attack":world.auto_attack,"wave":world.wave,"skill_levels":world.spells.levels.duplicate()}

func from_save_data(data: Dictionary) -> void:
	if int(data.get("version",0)) not in [1,2,3]:
		return
	world.stage = clampi(int(data.get("stage",0)),0,3)
	# Older practice saves retain progress and load safely into the new city hub.
	world.intro_seen = bool(data.get("intro_seen",world.stage>0))
	world.language = str(data.get("language","zh"))
	if world.language not in ["zh","en"]:
		world.language = "zh"
	world.rage = clampf(float(data.get("rage",0)),0,100)
	world.kills = maxi(0,int(data.get("kills",0)))
	world.wave = clampi(int(data.get("wave",1)),1,5)
	world.muted = bool(data.get("muted",false))
	world.auto_attack = bool(data.get("auto_attack",true))
	var levels=data.get("skill_levels",[1,1,1,1])
	if levels is Array and levels.size()==4:
		for i in range(4): world.spells.levels[i]=clampi(int(levels[i]),1,10)
