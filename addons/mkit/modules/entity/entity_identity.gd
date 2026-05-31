## What: EntityIdentity stores stable identity, display, faction, and tags for one entity instance.
## Responsibilities: expose entity id, definition id, display name, faction checks, and tag matching helpers.
## Upstream: EntitySpawner initializes identity from EntityDefinition and runtime ids.
## Downstream: combat targeting, events, rooms, inventory ownership, and UI read identity metadata.
## When to use: Add it to entity scenes that need stable ids, factions, or tag-based logic.
## Example: set `entity_id = "enemy_003"`, `definition_id = "slime"`, `faction = "enemy"`, `tags = ["beast"]`.
class_name EntityIdentity
extends Node

## Purpose: Inspector-exposed configuration `entity_id`.
## Example: `self.entity_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var entity_id: String = ""
## Purpose: Inspector-exposed configuration `definition_id`.
## Example: `self.definition_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var definition_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `faction`.
## Example: `self.faction = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var faction: String = "neutral"
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []


func _ready() -> void:
	if entity_id == "":
		entity_id = "%s_%d" % [name.to_snake_case(), Time.get_ticks_usec()]


## Purpose: Public method `has_tag` for external gameplay integration.
## Example: `self.has_tag(<tag>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_tag(tag: String) -> bool:
	return tags.has(tag)


## Purpose: Public method `has_any_tag` for external gameplay integration.
## Example: `self.has_any_tag(<input_tags>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_any_tag(input_tags: Array[String]) -> bool:
	for tag in input_tags:
		if tags.has(tag):
			return true
	return false


## Purpose: Public method `is_faction` for external gameplay integration.
## Example: `self.is_faction(<value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func is_faction(value: String) -> bool:
	return faction == value
