class_name StatDefinition
extends Resource

## Purpose: Inspector-exposed configuration `stat_id`.
## Example: `self.stat_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stat_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `default_value`.
## Example: `self.default_value = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var default_value: float = 0.0
## Purpose: Inspector-exposed configuration `min_value`.
## Example: `self.min_value = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var min_value: float = -INF
## Purpose: Inspector-exposed configuration `max_value`.
## Example: `self.max_value = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var max_value: float = INF
## Purpose: Inspector-exposed configuration `is_percent`.
## Example: `self.is_percent = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var is_percent: bool = false
