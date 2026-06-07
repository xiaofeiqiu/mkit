class_name HitboxComponent
extends Area2D
@export var active: bool = false
@export var base_damage: float = 1.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var hit_once_per_activation: bool = true
@export var target_factions: Array[String] = ["enemy"]
@export var hit_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = []
var source_entity: Node = null
var already_hit: Dictionary = {}


func _ready() -> void:
	source_entity = owner
	area_entered.connect(_on_area_entered)
	monitoring = true


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
	var result := _resolve_combat(request)
	var health := EntityContract.get_component(target, "HealthComponent") as HealthComponent
	if health != null:
		health.apply_damage(result)


func _resolve_combat(request: DamageRequest) -> DamageResult:
	var resolver: CombatService = null
	resolver = ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService
	if resolver == null:
		resolver = CombatService.new()
	return resolver.resolve(request)


func _is_valid_target(target: Node) -> bool:
	var identity := EntityContract.get_identity(target)
	if identity == null:
		return true
	return target_factions.has(identity.faction)


func _get_entity_id(entity: Node) -> String:
	var identity := EntityContract.get_identity(entity)
	if identity != null:
		return identity.entity_id
	return entity.name
