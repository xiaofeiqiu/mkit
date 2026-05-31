## What: RandomService wraps Godot RNG so gameplay randomness can be seeded and replayed consistently.
## Responsibilities: own the seed, provide random ranges/chance rolls, and pick weighted entries.
## Upstream: run generation, loot, combat rolls, and tests set or randomize the seed.
## Downstream: dungeon generation, reward selection, and combat calculations consume deterministic random values.
## When to use: Use it for gameplay decisions that must be reproducible from a run seed.
## Example: `random.set_seed(1842); var rare_drop := random.chance(0.15)`.
class_name RandomService
extends RefCounted

## Purpose: Public runtime field `seed_value`.
## Example: `self.seed_value = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var seed_value: int = 0
## Purpose: Public runtime field `rng`.
## Example: `self.rng = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var rng := RandomNumberGenerator.new()


## Purpose: Public method `set_seed` for external gameplay integration.
## Example: `self.set_seed(<value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_seed(value: int) -> void:
	seed_value = value
	rng.seed = value


## Purpose: Public method `randomize_seed` for external gameplay integration.
## Example: `self.randomize_seed()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func randomize_seed() -> int:
	rng.randomize()
	seed_value = rng.seed
	return seed_value


## Purpose: Public method `randf` for external gameplay integration.
## Example: `self.randf()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func randf() -> float:
	return rng.randf()


## Purpose: Public method `randi_range` for external gameplay integration.
## Example: `self.randi_range(<from>, <to>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)


## Purpose: Public method `randf_range` for external gameplay integration.
## Example: `self.randf_range(<from>, <to>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)


## Purpose: Public method `chance` for external gameplay integration.
## Example: `self.chance(<probability>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func chance(probability: float) -> bool:
	return randf() < clamp(probability, 0.0, 1.0)


## Purpose: Public method `weighted_pick` for external gameplay integration.
## Example: `self.weighted_pick(<entries>, <weight_property>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func weighted_pick(entries: Array, weight_property: String = "weight"):
	var total := 0.0
	for entry in entries:
		total += float(entry.get(weight_property))
	if total <= 0.0:
		return null

	var roll := randf_range(0.0, total)
	var cursor := 0.0
	for entry in entries:
		cursor += float(entry.get(weight_property))
		if roll <= cursor:
			return entry
	return entries[-1] if not entries.is_empty() else null
