class_name ContentValidationResult
extends RefCounted

var success: bool = true
var errors: Array[String] = []
var warnings: Array[String] = []


func add_error(message: String) -> void:
	success = false
	errors.append(message)


func add_warning(message: String) -> void:
	warnings.append(message)
