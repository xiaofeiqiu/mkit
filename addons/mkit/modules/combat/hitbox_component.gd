class_name HitboxComponent
extends Area2D
## 说明：`HitboxComponent` 是 战斗系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := HitboxComponent.new()`

## 编辑器配置：`active` 表示是否启用或当前激活状态，由 `HitboxComponent` 的公开 API 读取或维护。
@export var active: bool = false
## 编辑器配置：`base_damage` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var base_damage: float = 1.0
## 编辑器配置：`damage_type` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var damage_type: String = "physical"
## 编辑器配置：`element_type` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var element_type: String = "none"
## 编辑器配置：`hit_once_per_activation` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var hit_once_per_activation: bool = true
## 编辑器配置：`target_factions` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var target_factions: Array[String] = ["enemy"]
## 编辑器配置：`hit_tags` 表示标签集合，由 `HitboxComponent` 的公开 API 读取或维护。
@export var hit_tags: Array[String] = []
## 编辑器配置：`on_hit_statuses` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
@export var on_hit_statuses: Array[Dictionary] = []
## 运行时状态：`source_entity` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
var source_entity: Node = null
## 运行时状态：`already_hit` 表示 `HitboxComponent` 的字段值，由 `HitboxComponent` 的公开 API 读取或维护。
var already_hit: Dictionary = {}


func _ready() -> void:
	source_entity = owner
	area_entered.connect(_on_area_entered)
	monitoring = true


## 设置 `active` 对应的数据或对象，并保持 `HitboxComponent` 的领域契约一致。
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
	resolver = Mkit.combat()
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
