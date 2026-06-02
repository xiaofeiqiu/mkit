class_name EffectResult
extends RefCounted
var success: bool = true
var effect_id: String = ""
var failure_reason: String = ""
var payload: Dictionary = {}
var child_results: Array[EffectResult] = []


static func ok(id: String = "", data: Dictionary = {}) -> EffectResult:
	var r := EffectResult.new()
	r.success = true
	r.effect_id = id
	r.payload = data
	return r


static func fail(id: String, reason: String) -> EffectResult:
	var r := EffectResult.new()
	r.success = false
	r.effect_id = id
	r.failure_reason = reason
	return r
