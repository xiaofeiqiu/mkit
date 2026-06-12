class_name HitboxComponent
extends Area2D
## 说明：`HitboxComponent` 是 战斗系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := HitboxComponent.new()`

## Hitbox 是否当前参与命中检测；关闭时进入区域也不会结算伤害。
@export var active: bool = false
## 命中造成的基础伤害；CombatService 会继续应用伤害规则。
@export var base_damage: float = 1.0
## 伤害类型 id；用于抗性、格挡、事件标签或 UI 展示。
@export var damage_type: String = "physical"
## 元素类型 id；`none` 表示无元素，可用于弱点和抗性规则。
@export var element_type: String = "none"
## 同一次激活期间是否每个目标只命中一次。
@export var hit_once_per_activation: bool = true
## 允许命中的目标阵营列表；为空时调用方可选择不做阵营过滤。
@export var target_factions: Array[String] = ["enemy"]
## 随本次命中传递的标签；用于触发条件、状态和事件过滤。
@export var hit_tags: Array[String] = []
## 命中后尝试施加的状态配置列表；每项 Dictionary 应包含 status_id 等约定 key。
@export var on_hit_statuses: Array[Dictionary] = []
## 产生该 hitbox 的实体节点；用于伤害归因和状态来源。
var source_entity: Node = null
## 本次激活已经命中过的目标表；hit_once_per_activation 开启时用于去重。
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
