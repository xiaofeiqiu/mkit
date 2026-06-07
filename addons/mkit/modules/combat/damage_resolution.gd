class_name DamageResolution
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
var applied_status_effects: Array[DamageStatusApplication] = []
var trace: Dictionary = {}
var failure_reason: String = ""


func to_result() -> DamageResult:
	var result := DamageResult.new()
	result.source = source
	result.target = target
	result.base_amount = base_amount
	result.final_amount = final_amount
	result.damage_type = damage_type
	result.element_type = element_type
	result.was_critical = was_critical
	result.was_evaded = was_evaded
	result.was_blocked = was_blocked
	result.was_lethal = was_lethal
	result.applied_status_effects = []
	result.status_applications = []
	result.trace = trace.duplicate(true)
	result.trace["failure_reason"] = failure_reason
	for app in applied_status_effects:
		if app != null and app is DamageStatusApplication:
			result.applied_status_effects.append(app.status_id)
			result.status_applications.append(app.to_dictionary())
	return result
