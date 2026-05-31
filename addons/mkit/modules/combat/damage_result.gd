class_name DamageResult
extends RefCounted

var source: Node = null
var target: Node = null
var base_amount: float = 0.0
var final_amount: float = 0.0
var damage_type: String = "physical"
var element_type: String = "none"
var was_critical: bool = false
var was_evaded: bool = false
var was_blocked: bool = false
var was_lethal: bool = false
var applied_status_effects: Array[String] = [] # 命中并通过概率判定的 status_id 列表
var status_applications: Array[Dictionary] = [] # 待施加的完整条目: {status_id, stacks, duration}
var trace: Dictionary = {}


func to_debug_dict() -> Dictionary:
	return {
		"base_amount": base_amount,
		"final_amount": final_amount,
		"damage_type": damage_type,
		"element_type": element_type,
		"critical": was_critical,
		"evaded": was_evaded,
		"blocked": was_blocked,
		"lethal": was_lethal,
		"applied_status_effects": applied_status_effects,
		"trace": trace
	}
