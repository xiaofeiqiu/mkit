## What: UpgradeDefinition is authored content for one permanent or run-scoped upgrade.
## Responsibilities: define cost by level, prerequisites, unlocked content ids, effects, tags, and max level.
## Upstream: designers author upgrade resources and register them in ContentRegistry.
## Downstream: ProgressionSystem reads costs/prerequisites and applies effects when the upgrade levels up.
## When to use: Use it for meta upgrades, shop unlocks, skill-tree nodes, or permanent stat boosts.
## Example: `upgrade_id = "starter_hp"`, `currency_id = "meta_currency"`, `cost_by_level = [100, 250]`, `effects = [max_hp_bonus]`.
class_name UpgradeDefinition
extends Resource

## Purpose: Inspector-facing configuration `upgrade_id` for this class.
## Example: `self.upgrade_id = "value"`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var upgrade_id: String = ""
## Purpose: Inspector-facing configuration `display_name` for this class.
## Example: `self.display_name = "value"`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var display_name: String = ""
## Purpose: Inspector-facing configuration `description` for this class.
## Example: `self.description = "value"`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export_multiline var description: String = ""
## Purpose: Inspector-facing configuration `max_level` for this class.
## Example: `self.max_level = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var max_level: int = 1
## Purpose: Inspector-facing configuration `currency_id` for this class.
## Example: `self.currency_id = "value"`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var currency_id: String = "meta_currency"
## Purpose: Inspector-facing configuration `cost_by_level` for this class.
## Example: `self.cost_by_level = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var cost_by_level: Array[int] = [100]
## Purpose: Inspector-facing configuration `prerequisite_upgrade_ids` for this class.
## Example: `self.prerequisite_upgrade_ids = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var prerequisite_upgrade_ids: Array[String] = []
## Purpose: Inspector-facing configuration `unlock_content_ids` for this class.
## Example: `self.unlock_content_ids = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var unlock_content_ids: Array[String] = []
## Purpose: Inspector-facing configuration `effects` for this class.
## Example: `self.effects = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var effects: Array[GameEffect] = []
## Purpose: Inspector-facing configuration `tags` for this class.
## Example: `self.tags = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var tags: Array[String] = []
## Purpose: Inspector-facing configuration `is_meta_upgrade` for this class.
## Example: `self.is_meta_upgrade = true`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var is_meta_upgrade: bool = true


## Purpose: Public method `get_cost_for_level` used by external systems to invoke this class behavior.
## Example: `self.get_cost_for_level(next_level)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_cost_for_level(next_level: int) -> int:
	var index := max(0, next_level - 1)
	if index >= cost_by_level.size():
		return cost_by_level[-1] if not cost_by_level.is_empty() else 0
	return cost_by_level[index]
