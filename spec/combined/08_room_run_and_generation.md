# Room, Run, and Procedural Generation

---

# 16. Room / Run 模块接口设计

---

## 16.1 RoomDefinition

### 概念说明

- 是什么：一个房间类型的静态定义。
- 负责什么：定义房间场景路径、房间类型、难度、尺寸、敌人生成规则和奖励池。
- 为什么需要：地牢生成器应该选择 room.dungeon_small_01 这种稳定定义，而不是直接散落加载场景路径。
```gdscript
class_name RoomDefinition
extends Resource

@export var room_id: String = ""
@export var scene_path: String = ""
@export var room_type: String = "combat" # combat, shop, treasure, boss, event
@export var difficulty_rating: int = 1
@export var size: Vector2i = Vector2i(1, 1)
@export var tags: Array[String] = []
@export var enemy_spawn_ids: Array[String] = []
@export var reward_pool_ids: Array[String] = []
```

#### 字段说明
- **room_id**：房间定义或运行时房间 ID。例：room.dungeon_small_01 用于清房间、奖励和存档恢复。
- **scene_path**：资源或节点路径。例：用 scene_path 指向场景或节点，方便在 Inspector 中配置。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **enemy_spawn_ids**：要生成的实体定义 ID。例：enemy.goblin_basic 会通过 EntitySpawner 查找 EntityDefinition 并实例化场景。

---

### 27.62 RoomDefinition 使用示例

#### 详细实际用例

- 真实场景：`room.dungeon_small_01` 指向一个房间场景，类型 combat，难度 1，敌人池包含 goblin 和 slime。
- 怎么使用：DungeonGenerator 选择 RoomDefinition，RoomController 根据定义加载场景和生成敌人。
- 验证重点：房间定义可被 ContentRegistry 查到；缺失 scene_path 或 enemy id 时校验报错。
```gdscript
var room := RoomDefinition.new()
room.room_id = "room.dungeon_small_01"
room.scene_path = "res://game/rooms/dungeon_small_01.tscn"
room.room_type = "combat"
room.difficulty_rating = 1
room.enemy_spawn_ids = [
    "enemy.goblin_basic",
    "enemy.goblin_basic",
    "enemy.slime_basic"
]
room.reward_pool_ids = [
    "reward.attack_plus_20",
    "reward.max_hp_plus_10",
    "reward.potion_bundle"
]
```

---

---

---

## 16.2 RoomRuntime

### 概念说明

- 是什么：一间房在本局 Run 中的运行时状态。
- 负责什么：记录是否进入、是否清理、活跃敌人、已生成奖励和临时房间数据。
- 为什么需要：同一个 RoomDefinition 可以在不同 Run 里出现，每次的敌人、清理状态和奖励状态都不一样。
```gdscript
class_name RoomRuntime
extends RefCounted

var room_runtime_id: String = ""
var definition_id: String = ""
var cleared: bool = false
var entered: bool = false
var active_enemy_ids: Array[String] = []
var reward_options: Array[RewardOption] = []

static func create(definition_id: String) -> RoomRuntime:
    var r := RoomRuntime.new()
    r.room_runtime_id = "room_%d" % Time.get_ticks_usec()
    r.definition_id = definition_id
    return r
```

#### 字段说明
- **room_runtime_id**：稳定 ID 字段。例：RoomRuntime 通过 room_runtime_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **cleared**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **entered**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **reward_options**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **create()**：工厂方法。实际例子：掉落系统创建 ItemInstance 或 DomainEvent 时，用 create 保证 ID、时间戳和默认字段一次性设置完整。

---

### 27.63 RoomRuntime 使用示例

#### 详细实际用例

- 真实场景：玩家进入 `room.dungeon_small_01` 后，RoomRuntime 记录 entered=true，active_enemy_ids=[goblin_001, slime_001]。
- 怎么使用：静态房间数据放 RoomDefinition；本局的清理状态、敌人实例、奖励状态放 RoomRuntime。
- 验证重点：同一个房间定义在两次 run 中有各自 runtime，不互相污染。
```gdscript
var runtime := RoomRuntime.create("room.dungeon_small_01")
runtime.entered = true
runtime.active_enemy_ids = ["goblin_001", "slime_001"]
```

---

---

---

## 16.3 RoomController

### 概念说明

- 是什么：房间生命周期控制器。
- 负责什么：生成敌人、追踪存活敌人、判断清房间、开门并请求奖励。
- 为什么需要：房间是战斗、奖励和 Run 推进的交汇点，需要明确控制者。

```gdscript
class_name RoomController
extends Node

signal room_entered(room_id: String)
signal room_cleared(room_id: String)
signal reward_ready(options: Array[RewardOption])

@export var room_definition_id: String = ""
@export var enemy_container_path: NodePath = NodePath("Enemies")
@export var entity_spawner_path: NodePath = NodePath("EntitySpawner")
@export var reward_count: int = 3

var runtime: RoomRuntime = null
var active_enemies: Dictionary = {} # entity_id -> Node
var content: ContentRegistry = null
var entity_spawner: EntitySpawner = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry
    entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.entity_died.connect(_on_entity_died)

func setup(definition_id: String) -> void:
    room_definition_id = definition_id
    runtime = RoomRuntime.create(definition_id)

func enter_room() -> void:
    runtime.entered = true
    spawn_enemies()
    room_entered.emit(runtime.room_runtime_id)

func spawn_enemies() -> void:
    var def := get_definition()
    if def == null:
        return

    var parent := get_node_or_null(enemy_container_path)
    if parent == null:
        push_error("RoomController missing enemy container")
        return

    var spawner := _get_entity_spawner()
    if spawner == null:
        push_error("RoomController missing EntitySpawner")
        return

    for enemy_id in def.enemy_spawn_ids:
        var enemy := spawner.spawn_entity(enemy_id, parent)
        if enemy == null:
            continue
        var entity_id := _get_entity_id(enemy)
        active_enemies[entity_id] = enemy
        runtime.active_enemy_ids.append(entity_id)

func check_clear_condition() -> void:
    if runtime.cleared:
        return
    if active_enemies.is_empty():
        runtime.cleared = true
        # Generate rewards BEFORE announcing the clear. RunDirector.on_room_cleared
        # reads runtime.reward_options when room_cleared fires, so options must
        # already be populated or the reward screen would open empty.
        generate_reward()
        room_cleared.emit(runtime.room_runtime_id)
        var events := ServiceRegistry.get_service("events") as EventRouter
        if events != null:
            events.emit_room_cleared(runtime.room_runtime_id)

func generate_reward() -> void:
    var def := get_definition()
    if def == null:
        return
    var reward_system := RewardSystem.new()
    var ctx := GameplayContext.new()
    ctx.room_id = runtime.room_runtime_id
    var options := reward_system.generate_options(def.reward_pool_ids, reward_count, ctx)
    runtime.reward_options = options
    reward_ready.emit(options)

func get_definition() -> RoomDefinition:
    return content.get_resource(room_definition_id) as RoomDefinition

func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
    if active_enemies.has(entity_id):
        active_enemies.erase(entity_id)
        runtime.active_enemy_ids.erase(entity_id)
        check_clear_condition()

func _get_entity_spawner() -> EntitySpawner:
    if entity_spawner != null:
        return entity_spawner
    entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
    return entity_spawner

func _get_entity_id(entity: Node) -> String:
    var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity.entity_id if identity != null else entity.name
```

#### 字段说明
- **room_definition_id**：稳定 ID 字段。例：RoomController 通过 room_definition_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **enemy_container_path**：资源或节点路径。例：用 enemy_container_path 指向场景或节点，方便在 Inspector 中配置。
- **entity_spawner_path**：资源或节点路径。例：RoomController 通过它找到房间里的 EntitySpawner。
- **runtime**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
#### 信号说明
- **room_entered**：当 **RoomController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **room_cleared**：当 **RoomController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **reward_ready**：当 **RoomController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**RoomController** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **setup()**：公开 API。实际例子：外部系统通过它请求 **RoomController** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **enter_room()**：公开 API。实际例子：外部系统通过它请求 **RoomController** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **spawn_enemies()**：公开 API。实际例子：外部系统通过它请求 **RoomController** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **check_clear_condition()**：清理/重置入口。实际例子：切换存档、退出 run 或重启测试时调用，让 **RoomController** 清空自己的运行时缓存。
- **generate_reward()**：生成内容。实际例子：清房间后 RewardSystem.generate_options 生成三选一奖励。
- **get_definition()**：读取数据入口。实际例子：CombatResolver 通过 get_definition 获取最终攻击力，而不是直接读内部变量。
- **_on_entity_died()**：内部辅助函数。实际例子：由 **RoomController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_get_entity_spawner()**：内部辅助函数。实际例子：由 **RoomController** 查找本房间的 EntitySpawner，避免直接手写 enemy scene 加载。
- **_get_entity_id()**：内部辅助函数。实际例子：由 **RoomController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.64 RoomController 使用示例

#### 详细实际用例

- 真实场景：RoomController 进入房间时关门并刷敌人；监听 enemy_died；敌人全灭后开门并通知 RunDirector 生成奖励。
- 怎么使用：房间场景里的门、刷怪点、奖励点都由 RoomController 协调，不让敌人死亡脚本直接推进 run。
- 验证重点：最后一个敌人死亡只触发一次 room_cleared；奖励生成失败时有明确错误。
### 进入房间

```text
Room.tscn
  RoomController
  EntitySpawner
  Enemies
```

```gdscript
var controller := $RoomController as RoomController
controller.setup("room.dungeon_small_01")
controller.reward_ready.connect(_on_reward_ready)
controller.enter_room()
```

### 监听奖励生成

```gdscript
func _on_reward_ready(options: Array[RewardOption]) -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("reward_selection", {"options": options}, true)
```

---

---

---

## 16.4 RunState

### 概念说明

- 是什么：一局 roguelike run 的运行时存档对象。
- 负责什么：保存 run_id、seed、当前层、当前房间、临时升级、run currency、房间历史和奖励历史。
- 为什么需要：RunDirector 推进流程、存档恢复和 Debug 复现都需要一个权威 Run 状态。
```gdscript
class_name RunState
extends RefCounted

var run_id: String = ""
var seed: int = 0
var current_floor: int = 1
var current_room_index: int = 0
var current_room_id: String = ""
var elapsed_time: float = 0.0
var temporary_upgrade_ids: Array[String] = []
var run_currency: Dictionary = {}
var enemy_scaling_level: int = 1
var room_history: Array[String] = []
var reward_history: Array[String] = []
var rng_state: Dictionary = {}
var status: String = "not_started"

static func create(seed_value: int) -> RunState:
    var s := RunState.new()
    s.run_id = "run_%d" % Time.get_ticks_usec()
    s.seed = seed_value
    return s

func to_save_data() -> Dictionary:
    return {
        "run_id": run_id,
        "seed": seed,
        "current_floor": current_floor,
        "current_room_index": current_room_index,
        "current_room_id": current_room_id,
        "elapsed_time": elapsed_time,
        "temporary_upgrade_ids": temporary_upgrade_ids,
        "run_currency": run_currency,
        "enemy_scaling_level": enemy_scaling_level,
        "room_history": room_history,
        "reward_history": reward_history,
        "rng_state": rng_state,
        "status": status
    }
```

#### 字段说明
- **run_id**：一局 run 的 ID。例：Analytics 可以把所有 room_cleared 和 reward_selected 归到同一局。
- **seed**：随机种子。例：同一个 seed 生成同样房间顺序，方便复现 bug。
- **current_floor**：当前层数。例：第 3 层开始刷 elite 敌人。
- **current_room_id**：当前房间 ID。例：存档恢复时知道玩家正在哪个房间。
- **elapsed_time**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **room_history**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **reward_history**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **create()**：工厂方法。实际例子：掉落系统创建 ItemInstance 或 DomainEvent 时，用 create 保证 ID、时间戳和默认字段一次性设置完整。
- **to_save_data()**：序列化。实际例子：保存游戏时把背包、装备、RunState 转成 Dictionary。

---

### 27.65 RunState 使用示例

#### 详细实际用例

- 真实场景：一局 run 的 seed=12345，当前 floor=2，当前 room=room_07，已经选过 attack_plus_20。
- 怎么使用：RunDirector 修改 RunState，SaveManager 可选择保存它以支持中途退出继续。
- 验证重点：同 seed 重新生成房间图一致；读档后当前房间和临时升级恢复正确。
```gdscript
var run := RunState.create(12345)
run.current_floor = 1
run.current_room_id = "room.dungeon_small_01"
run.temporary_upgrade_ids.append("reward.attack_plus_20")

var save_data := run.to_save_data()
```

---

---

---

## 16.5 RunDirector

### 概念说明

- 是什么：一局 Roguelike Run 的导演。
- 负责什么：开始 Run、进入房间、处理奖励、推进楼层、死亡失败或胜利完成。
- 为什么需要：没有 RunDirector，房间、奖励、死亡和进度逻辑会分散到很多场景脚本。

```gdscript
class_name RunDirector
extends Node

signal run_started(run_state: RunState)
signal room_enter_requested(room_id: String)
signal choosing_reward(options: Array[RewardOption])
signal run_finished(result: String)

@export var first_floor_room_pool: Array[String] = []
@export var room_scene_container_path: NodePath = NodePath("RoomRoot")
@export var player_group: String = "player"
@export var player_entity_id: String = "player_001"

var run_state: RunState = null
var room_graph: RoomGraph = null
var current_room_controller: RoomController = null
var _events_connected: bool = false

func start_run(seed: int = 0) -> void:
    if seed == 0:
        seed = Time.get_ticks_usec()
    run_state = RunState.create(seed)
    run_state.status = "starting"

    var random := ServiceRegistry.get_service("random") as RandomService
    if random != null:
        random.set_seed(seed)

    room_graph = DungeonGenerator.new().generate_linear(first_floor_room_pool, seed, 8)
    run_state.status = "active"
    run_started.emit(run_state)

    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_run_started(run_state.run_id, seed)
        # Listen once for player death so a death ends the run (Failed).
        # RoomController consumes entity_died for enemies; RunDirector watches
        # specifically for the player's entity_id.
        if not _events_connected:
            events.entity_died.connect(_on_entity_died)
            _events_connected = true

    enter_next_room()

func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
    if run_state == null or run_state.status == "failed" or run_state.status == "completed":
        return
    if entity_id == player_entity_id:
        fail_run("player_died")

func enter_next_room() -> void:
    if room_graph == null:
        fail_run("missing_room_graph")
        return

    var room_node := room_graph.get_room_at(run_state.current_room_index)
    if room_node == null:
        complete_run()
        return

    run_state.current_room_id = room_node.room_definition_id
    run_state.room_history.append(room_node.room_definition_id)
    room_enter_requested.emit(room_node.room_definition_id)
    _load_room(room_node.room_definition_id)

func on_room_cleared(room_controller: RoomController) -> void:
    run_state.status = "choosing_reward"
    choosing_reward.emit(room_controller.runtime.reward_options)

func select_reward(option: RewardOption) -> void:
    var reward_system := RewardSystem.new()
    var ctx := GameplayContext.new()
    ctx.run_id = run_state.run_id
    var player := get_tree().get_first_node_in_group(player_group)
    ctx.source = player
    ctx.target = player
    var applied := reward_system.apply_selected(option, ctx)
    if applied:
        run_state.reward_history.append(option.reward_id)
        run_state.current_room_index += 1
        run_state.status = "active"
        enter_next_room()

func complete_run() -> void:
    run_state.status = "completed"
    run_finished.emit("completed")
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_run_finished(run_state.run_id, "completed")

func fail_run(reason: String) -> void:
    if run_state != null:
        run_state.status = "failed"
    run_finished.emit("failed:%s" % reason)
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_run_finished(run_state.run_id if run_state != null else "", "failed:%s" % reason)

func _load_room(room_definition_id: String) -> void:
    var content := ServiceRegistry.get_service("content") as ContentRegistry
    var def := content.get_resource(room_definition_id) as RoomDefinition
    if def == null:
        fail_run("missing_room_definition")
        return

    var scene := load(def.scene_path) as PackedScene
    if scene == null:
        fail_run("missing_room_scene")
        return

    var container := get_node(room_scene_container_path)
    for child in container.get_children():
        child.queue_free()

    var room := scene.instantiate()
    container.add_child(room)

    current_room_controller = room.get_node_or_null("RoomController") as RoomController
    if current_room_controller == null:
        fail_run("room_missing_controller")
        return

    current_room_controller.setup(room_definition_id)
    current_room_controller.room_cleared.connect(func(_id): on_room_cleared(current_room_controller))
    current_room_controller.enter_room()
```

#### 字段说明
- **room_scene_container_path**：资源或节点路径。例：用 room_scene_container_path 指向场景或节点，方便在 Inspector 中配置。
- **player_group**：玩家节点 group。例：选择奖励时用它找到奖励效果的 source/target。
#### 信号说明
- **run_started**：当 **RunDirector** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **room_enter_requested**：当 **RunDirector** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **choosing_reward**：当 **RunDirector** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **run_finished**：当 **RunDirector** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **start_run()**：启动流程。实际例子：RunDirector.start_run 创建 RunState 并进入第一个房间。
- **enter_next_room()**：公开 API。实际例子：外部系统通过它请求 **RunDirector** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **on_room_cleared()**：清理/重置入口。实际例子：切换存档、退出 run 或重启测试时调用，让 **RunDirector** 清空自己的运行时缓存。
- **select_reward()**：公开 API。实际例子：外部系统通过它请求 **RunDirector** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **complete_run()**：完成当前流程。实际例子：Action 到达结束条件后调用，发出 completed 信号并让状态机进入下一状态。
- **fail_run()**：公开 API。实际例子：玩家死亡或致命错误时结束 run 进入 Failed。
- **_on_entity_died()**：监听玩家死亡。实际例子：entity_died 的 entity_id 等于 player_entity_id 时调用 fail_run("player_died")。
- **_load_room()**：内部辅助函数。实际例子：由 **RunDirector** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.66 RunDirector 使用示例

#### 详细实际用例

- 真实场景：玩家点击 Start Run，RunDirector 创建 RunState，调用 DungeonGenerator，进入第一个 RoomController；清房间后进入 ChoosingReward 状态。
- 怎么使用：RunDirector 是 run 生命周期中心，不负责具体伤害、不负责 UI 绘制，只协调阶段推进。
- 验证重点：死亡时进入 Failed，Boss 通关进入 Completed，暂停时房间和 action 都按规则停下。
### 开始一局 Roguelike Run

```gdscript
func _on_start_button_pressed() -> void:
    var director := $RunDirector as RunDirector
    director.first_floor_room_pool = [
        "room.dungeon_small_01",
        "room.dungeon_small_02",
        "room.dungeon_elite_01"
    ]
    director.start_run(12345)
```

### 监听 Run 状态

```gdscript
func _ready() -> void:
    $RunDirector.run_started.connect(_on_run_started)
    $RunDirector.choosing_reward.connect(_on_choosing_reward)
    $RunDirector.run_finished.connect(_on_run_finished)

func _on_run_started(state: RunState) -> void:
    print("Run started with seed: ", state.seed)

func _on_choosing_reward(options: Array[RewardOption]) -> void:
    $UIManager.open_screen("reward_selection", {
        "options": options,
        "run_director": $RunDirector
    }, true)

func _on_run_finished(result: String) -> void:
    print("Run finished: ", result)
```

---

---

---

# 17. Procedural Generation 接口设计

---

## 17.1 RoomNode / RoomGraph

### 概念说明

- 是什么：程序生成地牢后的地图结构，RoomNode 是单个房间节点，RoomGraph 是房间连接图。
- 负责什么：表示起点、普通房、宝箱房、精英房、Boss 房以及它们之间的连接和顺序。
- 为什么需要：生成器不能只返回一串场景路径；RunDirector 需要可检查、可保存、可调试的地图结构。
```gdscript
class_name RoomNode
extends RefCounted

var node_id: String = ""
var room_definition_id: String = ""
var room_type: String = "combat"
var next_nodes: Array[RoomNode] = []
var previous_nodes: Array[RoomNode] = []
```

#### 字段说明
- **node_id**：稳定 ID 字段。例：RoomNode 通过 node_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **room_definition_id**：稳定 ID 字段。例：RoomNode 通过 room_definition_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **next_nodes**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **previous_nodes**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

```gdscript
class_name RoomGraph
extends RefCounted

var nodes: Array[RoomNode] = []
var start_node: RoomNode = null
var boss_node: RoomNode = null

func get_room_at(index: int) -> RoomNode:
    if index < 0 or index >= nodes.size():
        return null
    return nodes[index]
```

#### 字段说明
- **nodes**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **get_room_at()**：读取数据入口。实际例子：CombatResolver 通过 get_room_at 获取最终攻击力，而不是直接读内部变量。

---

### 27.67 RoomNode 使用示例

#### 详细实际用例

- 真实场景：生成地图后，第 0 个 RoomNode 是 start room，第 3 个是 treasure room，第 8 个是 boss room。
- 怎么使用：每个节点保存 room_definition_id、room_type 和连接关系，让 RunDirector 知道下一间去哪。
- 验证重点：RoomNode 不加载场景，只描述地图结构；加载发生在 RoomController/SceneRouter。
```gdscript
var node := RoomNode.new()
node.node_id = "room_node_001"
node.room_definition_id = "room.dungeon_small_01"
node.room_type = "combat"
```

---

---

---

### 27.68 RoomGraph 使用示例

#### 详细实际用例

- 真实场景：RoomGraph 表示一层地牢：start -> combat -> elite/treasure 分支 -> boss。
- 怎么使用：DungeonGenerator 返回 RoomGraph，RunDirector 根据玩家选择或线性顺序推进节点。
- 验证重点：起点和 boss 节点存在；每个连接都指向有效 RoomNode。
```gdscript
var graph := RoomGraph.new()
graph.nodes = [node_0, node_1, node_2]
graph.start_node = node_0
graph.boss_node = node_2

var current := graph.get_room_at(1)
print(current.room_definition_id)
```

---

---

---

## 17.2 DungeonGenerator

### 概念说明

- 是什么：确定性地牢图生成器。
- 负责什么：根据 seed 和房间池生成线性路径、分支、Boss 房等 RoomGraph。
- 为什么需要：确定性生成方便调试、存档、复现 bug 和未来做每日挑战。

```gdscript
class_name DungeonGenerator
extends RefCounted

func generate_linear(room_pool_ids: Array[String], seed: int, length: int) -> RoomGraph:
    var graph := RoomGraph.new()
    var rng := RandomNumberGenerator.new()
    rng.seed = seed

    var previous: RoomNode = null
    for i in range(length):
        var node := RoomNode.new()
        node.node_id = "room_node_%d" % i
        node.room_definition_id = room_pool_ids[rng.randi_range(0, room_pool_ids.size() - 1)]
        node.room_type = "combat"

        if previous != null:
            previous.next_nodes.append(node)
            node.previous_nodes.append(previous)
        else:
            graph.start_node = node

        graph.nodes.append(node)
        previous = node

    graph.boss_node = previous
    return graph
```

#### 函数使用场景
- **generate_linear()**：生成内容。实际例子：清房间后 RewardSystem.generate_options 生成三选一奖励。

---

---

### 27.69 DungeonGenerator 使用示例

#### 详细实际用例

- 真实场景：开始 run 时传入 seed=98765 和房间池，DungeonGenerator 生成 8 个房间，最后一个固定为 Boss。
- 怎么使用：生成器只输出 RoomGraph，不直接实例化场景；这样方便调试、预览和存档。
- 验证重点：相同 seed 和房间池生成相同图；不同 seed 产生不同但合法的图。
```gdscript
var generator := DungeonGenerator.new()
var graph := generator.generate_linear([
    "room.dungeon_small_01",
    "room.dungeon_small_02",
    "room.treasure_01"
], 98765, 8)

for node in graph.nodes:
    print(node.node_id, " -> ", node.room_definition_id)
```

---

