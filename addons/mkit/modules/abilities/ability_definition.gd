## What: AbilityDefinition is authored content for one castable ability.
## Responsibilities: define id, display data, cooldown, charges, cost, cast time, range, tags, conditions, and effects.
## Upstream: designers create resources and add them to ResourceDatabase/ContentRegistry.
## Downstream: AbilityController reads definitions to register, validate, cast, execute effects, and start cooldowns.
## When to use: Use it for player skills, enemy abilities, interact powers, spells, or weapon attacks.
## Example: `ability_id = "fireball"`, `cooldown = 3.0`, `cost_type = "mana"`, `effects = [fire_damage_effect]`.
class_name AbilityDefinition
extends Resource

## Purpose: Inspector-exposed configuration `ability_id`.
## Example: `self.ability_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var ability_id: String = ""
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
## Purpose: Inspector-exposed configuration `cooldown`.
## Example: `self.cooldown = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var cooldown: float = 1.0
## Purpose: Inspector-exposed configuration `charges`.
## Example: `self.charges = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var charges: int = 1
## Purpose: Inspector-exposed configuration `cost_type`.
## Example: `self.cost_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var cost_type: String = "none"
## Purpose: Inspector-exposed configuration `cost_amount`.
## Example: `self.cost_amount = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var cost_amount: float = 0.0
## Purpose: Inspector-exposed configuration `cast_time`.
## Example: `self.cast_time = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var cast_time: float = 0.0
## Purpose: Inspector-exposed configuration `range`.
## Example: `self.range = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var range: float = 0.0
## Purpose: Inspector-exposed configuration `tags`.
## Example: `self.tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var tags: Array[String] = []
## Purpose: Inspector-exposed configuration `conditions`.
## Example: `self.conditions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var conditions: Array[Condition] = []
## Purpose: Inspector-exposed configuration `effects`.
## Example: `self.effects = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var effects: Array[GameEffect] = []
