class_name EntityDefinition
extends Resource

## Purpose: Inspector-exposed configuration `entity_definition_id`.
## Example: `self.entity_definition_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var entity_definition_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `scene_path`.
## Example: `self.scene_path = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var scene_path: String = ""
## Purpose: Inspector-exposed configuration `default_faction`.
## Example: `self.default_faction = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var default_faction: String = "neutral"
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
## Purpose: Inspector-exposed configuration `base_stats`.
## Example: `self.base_stats = {}`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var base_stats: Dictionary = {}
## Purpose: Inspector-exposed configuration `starting_ability_ids`.
## Example: `self.starting_ability_ids = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var starting_ability_ids: Array[String] = []
## Purpose: Inspector-exposed configuration `loot_table_id`.
## Example: `self.loot_table_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var loot_table_id: String = ""
