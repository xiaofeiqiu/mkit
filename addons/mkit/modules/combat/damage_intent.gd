class_name DamageIntent
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
var on_hit_statuses: Array[Dictionary] = []
var payload: Dictionary = {}


static func from_request(request: DamageRequest) -> DamageIntent:
	var intent := DamageIntent.new()
	if request == null:
		return intent
	intent.source = request.source
	intent.target = request.target
	intent.base_amount = request.base_amount
	intent.damage_type = request.damage_type
	intent.element_type = request.element_type
	intent.can_crit = request.can_crit
	intent.can_evade = request.can_evade
	intent.can_block = request.can_block
	intent.tags = request.tags.duplicate()
	intent.on_hit_statuses = request.on_hit_statuses.duplicate()
	intent.payload = request.payload.duplicate(true)
	return intent
