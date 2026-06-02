class_name CloudSaveServiceMock
extends CloudSaveService
var _slots: Dictionary = {}


func is_available() -> bool:
	return true


func save_to_cloud(slot: String, data: Dictionary) -> void:
	_slots[slot] = data.duplicate(true)
	await get_tree().create_timer(0.2).timeout
	cloud_save_completed.emit(slot)
	print("[CloudSave] saved slot '%s'" % slot)


func load_from_cloud(slot: String) -> void:
	await get_tree().create_timer(0.2).timeout
	if _slots.has(slot):
		cloud_load_completed.emit(slot, _slots[slot].duplicate(true))
		print("[CloudSave] loaded slot '%s'" % slot)
	else:
		cloud_load_failed.emit(slot, "no_data")
		print("[CloudSave] slot '%s' not found" % slot)
