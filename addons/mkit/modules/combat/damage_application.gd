class_name DamageApplication
extends RefCounted
var resolution: DamageResolution = null


static func from_resolution(resolution: DamageResolution) -> DamageApplication:
	var app := DamageApplication.new()
	app.resolution = resolution
	return app


func to_result() -> DamageResult:
	if resolution == null:
		return DamageResult.new()
	return resolution.to_result()
