class_name RoomController
extends Node
## 说明：`RoomController` 是 房间与一局流程系统 的实体控制器，负责协调实体组件、服务和运行时状态。
## 上游：通常由 EntityRoot、CommandReceiver、状态机、玩家输入或 AI 创建或调用。
## 下游：会连接组件、ActionService、EffectService、ContentService 和 EventService，不直接依赖具体游戏内容。
## 使用：当项目实体需要把输入、状态机和组件能力组合成可调用行为时使用它。
## 示例：`var instance := RoomController.new()`

## 当 `RoomController` 发生 `room entered` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal room_entered(room_id: String)
## 当 `RoomController` 发生 `room cleared` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal room_cleared(room_id: String)
## 当 `RoomController` 发生 `reward ready` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal reward_ready(options: Array[RewardOption])
## 引用的 RoomDefinition id；房间控制器或节点按它加载静态配置。
@export var room_definition_id: String = ""
## 房间内敌人容器节点路径；用于统计清场和生成敌人。
@export var enemy_container_path: NodePath = NodePath("../Enemies")
## 房间使用的 EntitySpawner 节点路径；为空或无效时无法自动生成实体。
@export var entity_spawner_path: NodePath = NodePath("../EntitySpawner")
## 清场后生成的奖励选项数量。
@export var reward_count: int = 3
## 房间内可用生成坐标列表；为空时生成器需使用自身默认位置。
@export var spawn_positions: Array[Vector2] = []
## 当前领域运行时对象；服务方法会在创建后复用它。
var runtime: RoomRuntime = null
## 当前房间仍存活或未清理的敌人表。
var active_enemies: Dictionary = {}
## 房间用于生成实体的 EntitySpawner 引用；准备阶段由 entity_spawner_path 解析。
var entity_spawner: EntitySpawner = null


func _ready() -> void:
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	var events := Mkit.events()
	if events != null:
		events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died)


## 绑定运行时依赖并初始化内部状态；通常由 controller 或 service 在流程开始前调用。
func setup(definition_id: String) -> void:
	if definition_id.strip_edges() == "":
		push_warning("RoomController.setup: definition_id is empty")
		return
	room_definition_id = definition_id
	runtime = RoomRuntime.create(definition_id)


## 进入目标状态、房间或节点；会更新内部运行时字段并发出相关 signal 或 event。
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


## 执行 `spawn_enemies` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
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


## 执行 `check_clear_condition` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
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


## 读取配置资源生成运行时对象或结果；输入为空或无效时返回空结果。
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


## 读取当前对象中的 `definition`；未找到时返回 null、空集合或该 API 的默认值。
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


## 执行 `restore_runtime` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func restore_runtime(runtime_data: Dictionary) -> void:
	runtime = RoomRuntime.new()
	runtime.from_save_data(runtime_data)
