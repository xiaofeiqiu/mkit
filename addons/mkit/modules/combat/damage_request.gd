class_name DamageRequest
extends RefCounted

var source: Node = null
var target: Node = null
var base_amount: float = 0.0
var damage_type: String = "physical"
var element_type: String = "none"
var can_crit: bool = true
var can_evade: bool = true
var can_block: bool = true
var tags: Array[String] = []
var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}
var payload: Dictionary = {}
