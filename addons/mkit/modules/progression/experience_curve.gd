## What: ExperienceCurve defines XP required per level using explicit thresholds or a growth formula.
## Responsibilities: store max level, manual thresholds, base XP, growth factor, and compute XP needed for a level.
## Upstream: designers attach it to ExperienceComponent resources or scene nodes.
## Downstream: ExperienceComponent queries it for level-up checks and UI progress.
## When to use: Use it to tune player, weapon, pet, or account level pacing without code changes.
## Example: `max_level = 10`, `base_xp = 100`, `growth_factor = 1.35` gives rising level thresholds.
class_name ExperienceCurve
extends Resource

## Purpose: Inspector-facing configuration `max_level` for this class.
## Example: `self.max_level = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var max_level: int = 20
## Manual per-level XP thresholds. xp_thresholds[0] = XP to go from lv1→lv2, etc.
## When empty, the formula (base_xp * growth_factor^(level-1)) is used instead.
## Purpose: Inspector-facing configuration `xp_thresholds` for this class.
## Example: `self.xp_thresholds = []`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var xp_thresholds: Array[int] = []
## Purpose: Inspector-facing configuration `base_xp` for this class.
## Example: `self.base_xp = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var base_xp: int = 100
## Purpose: Inspector-facing configuration `growth_factor` for this class.
## Example: `self.growth_factor = 1.0`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var growth_factor: float = 1.5


## Returns XP required to advance FROM `level` to `level + 1`.
## Returns 0 when already at max_level.
## Purpose: Public method `get_xp_required` used by external systems to invoke this class behavior.
## Example: `self.get_xp_required(1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_xp_required(level: int) -> int:
	if level >= max_level:
		return 0
	var index := level - 1
	if index < xp_thresholds.size():
		return xp_thresholds[index]
	return int(base_xp * pow(growth_factor, index))
