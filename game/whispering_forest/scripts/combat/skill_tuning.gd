extends RefCounted

# Stable elemental IDs. The earth meteor is deliberately not the rage ultimate.
const IDS := ["SK09", "SK10", "SK11", "SK12"]
const ZH := ["火爆术", "风刃·龙卷", "陨石术", "冰冻术"]
const EN := ["Flame Burst", "Gale Tornado", "Rockfall", "Ice Pillars"]
const ELEMENTS := ["fire", "wind", "earth", "water"]
# New production target. Ice is migrated first; other clips keep their actual
# eight authored poses until their Aseprite replacements are produced.
const ANIMATION_FRAMES := 16
static func frame_count(kind: String) -> int:
	return ANIMATION_FRAMES if kind=="ice" else 8
# Time from the first to the last release; individual animations are excluded.
const MULTI_RELEASE_WINDOW := 0.8
# Existing levels 2–10; level 1 now derives timing from fire_cue.gd's WAV.
const FIRE_LIFE := 2.4
const FIRE_HIT := 0.36
const EARTH_FALL := 0.95
const EARTH_TAIL := 1.0
const IceMotion = preload("res://game/whispering_forest/art/combat/ice_motion.gd")
const ICE_LIFE := IceMotion.LIFE
const ICE_RISE := IceMotion.TIMES[6]
const ICE_PEAK := IceMotion.TIMES[IceMotion.PEAK_FRAME]
const ICE_HIT := ICE_PEAK
const ICE_SETTLE := IceMotion.TIMES[IceMotion.PEAK_FRAME+1]
const ICE_FADE := IceMotion.FADE
const WIND_TAIL := 0.9
const CARDS := [
	["area", "广域施法", "Wider spells", [0.15,0.30,0.50]],
	["speed", "迅捷施法", "Faster casting", [0.10,0.20,0.35]],
	["projectiles", "多重投射", "Extra projectiles", [1,2,3]],
	["bounces", "折返轨迹", "Ricochet", [1,2,3]],
	["move", "轻盈步伐", "Fleet foot", [0.08,0.15,0.25]],
	["health", "生命强化", "Vitality", [0.15,0.30,0.50]],
	["crit", "弱点洞察", "Keen eye", [0.04,0.08,0.12]],
	["damage", "元素共鸣", "Elemental power", [0.12,0.25,0.45]],
	["rage", "怒气涌流", "Rage flow", [0.15,0.30,0.50]],
]

static func definition(index: int, level: int, mods: Dictionary = {}) -> Dictionary:
	var rank := clampi(level,1,10)
	var progress := float(rank-1)/9.0
	var area := sqrt(1.0+float(mods.get("area",0.0)))
	var cast_speed:=minf(2.5,1.0+float(mods.get("speed",0.0)))
	return {
		"level":rank, "element":ELEMENTS[index],
		"radius":lerpf([42.0,23.0,38.0,36.0][index],[105.0,49.0,76.0,90.0][index],progress)*area,
		"damage":[48.0,15.0,65.0,40.0][index]*(1.0+0.22*(rank-1))*(1.0+float(mods.get("damage",0.0))),
		"cooldown":[2.8,5.0,5.8,6.5][index]/minf(2.5,1.0+float(mods.get("speed",0.0))),
		"count":mini(8,1+int((rank-1)/3)+int(mods.get("projectiles",0))),
		"release_window":MULTI_RELEASE_WINDOW/cast_speed,
		"bounces":mini(16,1+int((rank-1)/3)+int(mods.get("bounces",0))),
		"duration":lerpf(7.5,10.5,progress), "freeze":lerpf(0.55,1.4,progress),
	}
