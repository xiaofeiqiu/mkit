## What: EquipmentController manages equipped ItemInstance objects by equipment slot.
## Responsibilities: validate slots/item definitions, equip/unequip items, apply/remove stat modifiers, and emit equipment changes.
## Upstream: inventory UI, commands, loot/reward choices, or tests call equip and unequip.
## Downstream: StatsComponent receives item stat modifiers and UI listens for equipment_changed.
## When to use: Attach it to entities that can wear gear or weapons affecting stats.
## Example: `$EquipmentController.equip(sword_instance, "weapon"); var ring := $EquipmentController.unequip("ring")`.
class_name EquipmentController
extends Node

## Purpose: Emits the `equipment_changed` signal to notify external listeners of a state change.
## Example: `self.equipment_changed.connect(_on_equipment_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal equipment_changed(slot_id: String, item: ItemInstance)

## Purpose: Inspector-exposed configuration `allowed_slots`.
## Example: `self.allowed_slots = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var allowed_slots: Array[String] = ["weapon", "helmet", "armor", "ring", "amulet"]

## Purpose: Public runtime field `equipped`.
## Example: `self.equipped = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var equipped: Dictionary = {}
## Purpose: Public runtime field `content`.
## Example: `self.content = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var content: ContentRegistry = null


func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry


## Purpose: Public method `can_equip` for external gameplay integration.
## Example: `self.can_equip(<item>, <slot_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func can_equip(item: ItemInstance, slot_id: String) -> bool:
	if item == null:
		return false
	if not allowed_slots.has(slot_id):
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	return definition.equipment_slot == slot_id


## Purpose: Public method `equip` for external gameplay integration.
## Example: `self.equip(<item>, <slot_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func equip(item: ItemInstance, slot_id: String) -> bool:
	if not can_equip(item, slot_id):
		return false

	if equipped.has(slot_id):
		unequip(slot_id)

	equipped[slot_id] = item
	_apply_item_modifiers(item)
	equipment_changed.emit(slot_id, item)
	return true


## Purpose: Public method `unequip` for external gameplay integration.
## Example: `self.unequip(<slot_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func unequip(slot_id: String) -> ItemInstance:
	if not equipped.has(slot_id):
		return null
	var item := equipped[slot_id] as ItemInstance
	_remove_item_modifiers(item)
	equipped.erase(slot_id)
	equipment_changed.emit(slot_id, null)
	return item


## Purpose: Public method `get_equipped` for external gameplay integration.
## Example: `self.get_equipped(<slot_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_equipped(slot_id: String) -> ItemInstance:
	return equipped.get(slot_id, null)


## Purpose: Public method `get_item_definition` for external gameplay integration.
## Example: `self.get_item_definition(<item_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_item_definition(item_id: String) -> ItemDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	return content.get_resource(item_id) as ItemDefinition


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
