class_name DamageStatusApplication
extends RefCounted
var status_id: String = ""
var stacks: int = 1
var duration: float = -1.0


static func from_dictionary(raw: Dictionary) -> DamageStatusApplication:
	var app := DamageStatusApplication.new()
	app.status_id = str(raw.get("status_id", ""))
	app.stacks = int(raw.get("stacks", 1))
	app.duration = float(raw.get("duration", -1.0))
	return app


static func from_values(status_id: String, stacks: int = 1, duration: float = -1.0) -> DamageStatusApplication:
	var app := DamageStatusApplication.new()
	app.status_id = status_id
	app.stacks = max(1, stacks)
	app.duration = duration
	return app


func to_dictionary() -> Dictionary:
	return {"status_id": status_id, "stacks": stacks, "duration": duration}
