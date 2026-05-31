## What: RewardDefinition is authored content for a selectable reward.
## Responsibilities: define id, display data, rarity, weight, conditions, and effects to apply when selected.
## Upstream: designers author reward resources and register them in content databases.
## Downstream: RewardSystem builds RewardOption objects and applies selected effects through EffectExecutor.
## When to use: Use it for run upgrades, item grants, healing choices, currency bonuses, or unlock rewards.
## Example: `reward_id = "gain_iron_sword"`, `rarity = "rare"`, `effects = [grant_iron_sword_effect]`.
class_name RewardDefinition
extends Resource

## Purpose: Inspector-exposed configuration `reward_id`.
## Example: `self.reward_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var reward_id: String = ""
## Purpose: Inspector-exposed configuration `display_name`.
## Example: `self.display_name = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var display_name: String = ""
## Purpose: Inspector-exposed configuration `description`.
## Example: `self.description = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export_multiline var description: String = ""
## Purpose: Inspector-exposed configuration `icon`.
## Example: `self.icon = null`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var icon: Texture2D
## Purpose: Inspector-exposed configuration `rarity`.
## Example: `self.rarity = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var rarity: String = "common"
## Purpose: Inspector-exposed configuration `weight`.
## Example: `self.weight = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var weight: float = 1.0
## Purpose: Inspector-exposed configuration `conditions`.
## Example: `self.conditions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var conditions: Array[Condition] = []
## Purpose: Inspector-exposed configuration `effects`.
## Example: `self.effects = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effects: Array[GameEffect] = []


## Purpose: Public method `get_resource_id` for external gameplay integration.
## Example: `self.get_resource_id()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_resource_id() -> String:
	return reward_id
