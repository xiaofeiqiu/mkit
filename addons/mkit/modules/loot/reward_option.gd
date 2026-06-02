class_name RewardOption
extends RefCounted
var reward_id: String = ""
var display_name: String = ""
var description: String = ""
var icon: Texture2D = null
var rarity: String = "common"
var source: String = ""
var effects: Array[GameEffect] = []
var payload: Dictionary = {}
