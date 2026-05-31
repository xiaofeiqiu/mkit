## What: HurtboxComponent is an Area2D marker for damage-receiving space on an entity.
## Responsibilities: expose the owning entity, damage receive toggle, multiplier, and damage tags.
## Upstream: HitboxComponent detects HurtboxComponent overlaps during active attack windows.
## Downstream: CombatResolver and HealthComponent use the resolved owner entity and damage metadata.
## When to use: Attach it to enemies, players, weak points, shields, or destructible parts that can be hit.
## Example: set `owner_path = NodePath("../..")` and `damage_multiplier = 1.5` for a weak-point hurtbox.
class_name HurtboxComponent
extends Area2D

## Purpose: Inspector-exposed configuration `owner_path`.
## Example: `self.owner_path = NodePath(".")`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var owner_path: NodePath = NodePath("../..")
## Purpose: Inspector-exposed configuration `can_receive_damage`.
## Example: `self.can_receive_damage = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var can_receive_damage: bool = true
## Purpose: Inspector-exposed configuration `damage_multiplier`.
## Example: `self.damage_multiplier = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var damage_multiplier: float = 1.0
## Purpose: Inspector-exposed configuration `damage_tags`.
## Example: `self.damage_tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var damage_tags: Array[String] = []


## Purpose: Public method `get_owner_entity` for external gameplay integration.
## Example: `self.get_owner_entity()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_owner_entity() -> Node:
	return get_node_or_null(owner_path)
