class_name EquipmentController
extends SaveableComponent
signal equipment_changed(slot_id: String, item: ItemInstance)
@export var allowed_slots: Array[String] = ["weapon", "helmet", "armor", "ring", "amulet"]
var equipped: Dictionary = {}
var content: ContentService = null


func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentService


func can_equip(item: ItemInstance, slot_id: String) -> bool:
	if item == null:
		return false
	if not allowed_slots.has(slot_id):
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	return definition.equipment_slot == slot_id


func equip(item: ItemInstance, slot_id: String) -> bool:
	if not can_equip(item, slot_id):
		return false
	if equipped.has(slot_id):
		unequip(slot_id)
	equipped[slot_id] = item
	_apply_item_modifiers(item)
	equipment_changed.emit(slot_id, item)
	return true


func unequip(slot_id: String) -> ItemInstance:
	if not equipped.has(slot_id):
		return null
	var item := equipped[slot_id] as ItemInstance
	_remove_item_modifiers(item)
	equipped.erase(slot_id)
	equipment_changed.emit(slot_id, null)
	return item


func get_equipped(slot_id: String) -> ItemInstance:
	return equipped.get(slot_id, null)


func get_item_definition(item_id: String) -> ItemDefinition:
	if content == null:
		if ServiceRegistry.has_service("content"):
			content = ServiceRegistry.get_service("content") as ContentService
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition


func to_save_data() -> Dictionary:
	var slots: Dictionary = {}
	for slot_id in equipped.keys():
		var item := equipped[slot_id] as ItemInstance
		if item != null:
			slots[str(slot_id)] = item.to_save_data()
	return {"slots": slots}


func from_save_data(data: Dictionary) -> void:
	for item in equipped.values():
		if item is ItemInstance:
			_remove_item_modifiers(item)
	equipped.clear()
	var slots: Dictionary = data.get("slots", {})
	for slot_id in slots.keys():
		var key := str(slot_id)
		if not allowed_slots.has(key):
			continue
		var raw: Variant = slots[slot_id]
		if raw is Dictionary:
			var item := ItemInstance.from_save_data(raw)
			equipped[key] = item
			_apply_item_modifiers(item)
			equipment_changed.emit(key, item)


func _apply_item_modifiers(item: ItemInstance) -> void:
	var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats == null:
		return
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return
	for mod_def in definition.stat_modifiers:
		stats.add_modifier(StatModifier.from_definition(mod_def, item.instance_id))
	for rolled in item.rolled_affixes:
		rolled.source_id = item.instance_id
		stats.add_modifier(rolled)


func _remove_item_modifiers(item: ItemInstance) -> void:
	var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats != null:
		stats.remove_modifiers_from_source(item.instance_id)
