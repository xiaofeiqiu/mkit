class_name HitboxComponent
extends Area2D

## Purpose: Inspector-exposed configuration `active`.
## Example: `self.active = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var active: bool = false
## Purpose: Inspector-exposed configuration `base_damage`.
## Example: `self.base_damage = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var base_damage: float = 1.0
## Purpose: Inspector-exposed configuration `damage_type`.
## Example: `self.damage_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var damage_type: String = "physical"
## Purpose: Inspector-exposed configuration `element_type`.
## Example: `self.element_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var element_type: String = "none"
## Purpose: Inspector-exposed configuration `hit_once_per_activation`.
## Example: `self.hit_once_per_activation = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var hit_once_per_activation: bool = true
## Purpose: Inspector-exposed configuration `target_factions`.
## Example: `self.target_factions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var target_factions: Array[String] = ["enemy"]
## Purpose: Inspector-exposed configuration `hit_tags`.
## Example: `self.hit_tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var hit_tags: Array[String] = []
## Purpose: Inspector-exposed configuration `on_hit_statuses`.
## Example: `self.on_hit_statuses = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}

## Purpose: Public runtime field `source_entity`.
## Example: `self.source_entity = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var source_entity: Node = null
## Purpose: Public runtime field `already_hit`.
## Example: `self.already_hit = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var already_hit: Dictionary = {}


func _ready() -> void:
	source_entity = owner
	area_entered.connect(_on_area_entered)
	# Keep monitoring on at all times and gate damage with `active`. This lets us
	# both (a) catch hurtboxes that *enter* during the active window via the
	# area_entered signal and (b) catch hurtboxes that were *already overlapping*
	# when the window opens (see set_active -> _scan_overlaps). The spec's
	# monitoring=active toggle would miss case (b) for a stationary target the
	# attacker is already next to.
	monitoring = true


## Purpose: Public method `set_active` for external gameplay integration.
## Example: `self.set_active(<value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_active(value: bool) -> void:
	active = value
	if value:
		already_hit.clear()
		_scan_overlaps()


func _scan_overlaps() -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		_try_hit(area as HurtboxComponent)


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	_try_hit(area as HurtboxComponent)


func _try_hit(hurtbox: HurtboxComponent) -> void:
	if hurtbox == null:
		return
	if not hurtbox.can_receive_damage:
		return
	var target := hurtbox.get_owner_entity()
	if target == null:
		return

	var target_id := _get_entity_id(target)
	if hit_once_per_activation and already_hit.has(target_id):
		return

	if not _is_valid_target(target):
		return

	already_hit[target_id] = true

	var request := DamageRequest.new()
	request.source = source_entity
	request.target = target
	request.base_amount = base_damage * hurtbox.damage_multiplier
	request.damage_type = damage_type
	request.element_type = element_type
	request.tags = hit_tags.duplicate()
	request.tags.append_array(hurtbox.damage_tags)
	request.on_hit_statuses = on_hit_statuses.duplicate()

	var result := CombatResolver.get_default().resolve(request)
	var health := target.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health != null:
		health.apply_damage(result)


func _is_valid_target(target: Node) -> bool:
	var identity := target.get_node_or_null("EntityIdentity") as EntityIdentity
	if identity == null:
		return true
	return target_factions.has(identity.faction)


func _get_entity_id(entity: Node) -> String:
	var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
	if identity != null:
		return identity.entity_id
	return entity.name
