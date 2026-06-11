class_name RoomController
extends Node
## 说明：`RoomController` 是 房间与一局流程系统 的实体控制器，负责协调实体组件、服务和运行时状态。
## 上游：通常由 EntityRoot、CommandReceiver、StateMachine、玩家输入或 AI 创建或调用。
## 下游：会连接组件、ActionService、EffectService、ContentService 和 EventService，不直接依赖具体游戏内容。
## 使用：当项目实体需要把输入、状态机和组件能力组合成可调用行为时使用它。
## 示例：`var instance := RoomController.new()`

## 当 `RoomController` 发生 `room entered` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal room_entered(room_id: String)
## 当 `RoomController` 发生 `room cleared` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal room_cleared(room_id: String)
## 当 `RoomController` 发生 `reward ready` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal reward_ready(options: Array[RewardOption])
## 编辑器配置：`room_definition_id` 表示稳定 id，由 `RoomController` 的公开 API 读取或维护。
@export var room_definition_id: String = ""
## 编辑器配置：`enemy_container_path` 表示资源或节点路径，由 `RoomController` 的公开 API 读取或维护。
@export var enemy_container_path: NodePath = NodePath("../Enemies")
## 编辑器配置：`entity_spawner_path` 表示资源或节点路径，由 `RoomController` 的公开 API 读取或维护。
@export var entity_spawner_path: NodePath = NodePath("../EntitySpawner")
## 编辑器配置：`reward_count` 表示数量上限或计数，由 `RoomController` 的公开 API 读取或维护。
@export var reward_count: int = 3
## 编辑器配置：`spawn_positions` 表示 `RoomController` 的字段值，由 `RoomController` 的公开 API 读取或维护。
@export var spawn_positions: Array[Vector2] = []
## 运行时状态：`runtime` 表示运行时数据，由 `RoomController` 的公开 API 读取或维护。
var runtime: RoomRuntime = null
## 运行时状态：`active_enemies` 表示是否启用或当前激活状态，由 `RoomController` 的公开 API 读取或维护。
var active_enemies: Dictionary = {}
## 运行时状态：`entity_spawner` 表示 `RoomController` 的字段值，由 `RoomController` 的公开 API 读取或维护。
var entity_spawner: EntitySpawner = null


func _ready() -> void:
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	var events := Mkit.events()
	if events != null:
		events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)


## 初始化运行时依赖和起始状态，并保持 `RoomController` 的领域契约一致。
func setup(definition_id: String) -> void:
	if definition_id.strip_edges() == "":
		push_warning("RoomController.setup: definition_id is empty")
		return
	room_definition_id = definition_id
	runtime = RoomRuntime.create(definition_id)


## 进入对应状态、房间或节点，并保持 `RoomController` 的领域契约一致。
func enter_room() -> void:
	if runtime == null:
		if room_definition_id.strip_edges() == "":
			push_warning("RoomController.enter_room: missing runtime and room_definition_id")
			return
		runtime = RoomRuntime.create(room_definition_id)
	runtime.entered = true
	if not runtime.cleared:
		spawn_enemies()
	room_entered.emit(runtime.room_runtime_id)


## 执行 `spawn_enemies` 对应的公开操作，并保持 `RoomController` 的领域契约一致。
func spawn_enemies() -> void:
	if runtime == null:
		push_error("RoomController.spawn_enemies: runtime is null")
		return
	var def := get_definition()
	if def == null:
		return
	var parent := get_node_or_null(enemy_container_path)
	if parent == null:
		push_error("RoomController: missing enemy container at %s" % enemy_container_path)
		return
	var spawner := _get_entity_spawner()
	if spawner == null:
		push_error("RoomController: missing EntitySpawner at %s" % entity_spawner_path)
		return
	var runtime_spawn_count: int = def.enemy_spawn_ids.size()
	if not runtime.active_enemy_ids.is_empty():
		runtime_spawn_count = min(runtime.active_enemy_ids.size(), runtime_spawn_count)
	active_enemies.clear()
	runtime.active_enemy_ids.clear()
	for index in range(runtime_spawn_count):
		if index >= def.enemy_spawn_ids.size():
			break
		var enemy_def_id := def.enemy_spawn_ids[index]
		var pos := Vector2.ZERO
		if index < spawn_positions.size():
			pos = spawn_positions[index]
		var enemy := spawner.spawn_entity(enemy_def_id, parent, pos)
		if enemy == null:
			continue
		var entity_id := _get_entity_id(enemy)
		active_enemies[entity_id] = enemy
		runtime.active_enemy_ids.append(entity_id)


## 执行 `check_clear_condition` 对应的公开操作，并保持 `RoomController` 的领域契约一致。
func check_clear_condition() -> void:
	if runtime == null or runtime.cleared:
		return
	if active_enemies.is_empty():
		runtime.cleared = true
		generate_reward()
		room_cleared.emit(runtime.room_runtime_id)
		var events := Mkit.events()
		if events != null:
			events.emit_domain_event(WorldEvents.room_cleared(runtime.room_runtime_id))


## 根据配置生成运行时结果，并保持 `RoomController` 的领域契约一致。
func generate_reward() -> void:
	if runtime == null:
		reward_ready.emit([])
		return
	if reward_count <= 0:
		runtime.reward_options = []
		reward_ready.emit([])
		return
	var def := get_definition()
	if def == null or def.reward_pool_ids.is_empty():
		reward_ready.emit([])
		return
	var reward_system := Mkit.loot()
	if reward_system == null:
		reward_ready.emit([])
		return
	var ctx := GameplayContext.from_context()
	ctx.payload["room_id"] = runtime.room_runtime_id
	var options := reward_system.generate_options(def.reward_pool_ids, reward_count, ctx)
	runtime.reward_options = options
	reward_ready.emit(options)


## 返回 `definition` 对应的数据或对象，并保持 `RoomController` 的领域契约一致。
func get_definition() -> RoomDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(room_definition_id) as RoomDefinition


func _on_entity_died(event: DomainEvent) -> void:
	if runtime == null:
		return
	var entity_id := str(event.payload.get("entity_id", event.source_id))
	if not active_enemies.has(entity_id):
		return
	active_enemies.erase(entity_id)
	runtime.active_enemy_ids.erase(entity_id)
	check_clear_condition()


func _get_entity_spawner() -> EntitySpawner:
	if entity_spawner != null:
		return entity_spawner
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	return entity_spawner


func _get_entity_id(entity: Node) -> String:
	return EntityContract.get_entity_id(entity)


## 执行 `restore_runtime` 对应的公开操作，并保持 `RoomController` 的领域契约一致。
func restore_runtime(runtime_data: Dictionary) -> void:
	runtime = RoomRuntime.new()
	runtime.from_save_data(runtime_data)
