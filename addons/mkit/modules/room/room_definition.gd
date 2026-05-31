class_name RoomDefinition
extends Resource

## Purpose: Inspector-exposed configuration `room_id`.
## Example: `self.room_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var room_id: String = ""
## Purpose: Inspector-exposed configuration `scene_path`.
## Example: `self.scene_path = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var scene_path: String = ""
## Purpose: Inspector-exposed configuration `room_type`.
## Example: `self.room_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var room_type: String = "combat"
## Purpose: Inspector-exposed configuration `difficulty_rating`.
## Example: `self.difficulty_rating = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var difficulty_rating: int = 1
## Purpose: Inspector-exposed configuration `size`.
## Example: `self.size = Vector2i(0, 0)`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var size: Vector2i = Vector2i(1, 1)
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
## Purpose: Inspector-exposed configuration `enemy_spawn_ids`.
## Example: `self.enemy_spawn_ids = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var enemy_spawn_ids: Array[String] = []
## Purpose: Inspector-exposed configuration `reward_pool_ids`.
## Example: `self.reward_pool_ids = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var reward_pool_ids: Array[String] = []
