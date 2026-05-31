# Runtime Kernel

---

# 2. Runtime Kernel 接口设计

---

## 2.1 ServiceRegistry

### 概念说明

- 是什么：运行时全局服务的轻量目录。
- 负责什么：注册和解析 Random、Time、EventRouter、ContentRegistry、CommandRouter、SceneRouter、SaveManager、ProgressionSystem、Analytics 等真正全局服务。
- 为什么需要：很多系统需要共享服务，但不应该到处硬编码 Autoload 路径；统一注册也方便测试时替换成 mock。

### 设计目的

集中注册真正全局的服务，例如 Random、Time、ContentRegistry、EventRouter、SceneRouter、SaveManager、ProgressionSystem、Analytics。

不要把具体 gameplay object 注册成 service。

### 文件

`res://addons/mkit/kernel/services/service_registry.gd`

### 接口

```gdscript
# Registered by plugin.gd as the autoload singleton "ServiceRegistry".
# IMPORTANT: do NOT declare `class_name ServiceRegistry` here — in Godot 4 an
# autoload name cannot collide with a class_name. Access it everywhere through
# the autoload global (e.g. ServiceRegistry.get_service("events")).
extends Node

var _services: Dictionary = {}
var _service_types: Dictionary = {}

func register_service(service_id: String, service: Object, expected_class_name: String = "") -> void:
    assert(service_id != "")
    assert(service != null)
    if _services.has(service_id):
        push_warning("Service already registered: %s. It will be replaced." % service_id)
    _services[service_id] = service
    if expected_class_name != "":
        _service_types[service_id] = expected_class_name

func has_service(service_id: String) -> bool:
    return _services.has(service_id)

func get_service(service_id: String) -> Object:
    if not _services.has(service_id):
        push_error("Missing service: %s" % service_id)
        return null
    return _services[service_id]

func get_typed(service_id: String, expected_class_name: String) -> Object:
    var service := get_service(service_id)
    if service == null:
        return null
    if expected_class_name != "" and service.get_class() != expected_class_name and not service.is_class(expected_class_name):
        push_warning("Service %s may not match expected type %s" % [service_id, expected_class_name])
    return service

func unregister_service(service_id: String) -> void:
    _services.erase(service_id)
    _service_types.erase(service_id)

func clear() -> void:
    _services.clear()
    _service_types.clear()
```

#### 函数使用场景
- **register_service()**：注册入口。实际例子：GameBootstrap 启动时把 EventRouter 注册为 events 服务。
- **has_service()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **get_service()**：读取数据入口。实际例子：CombatResolver 通过 get_service 获取最终攻击力，而不是直接读内部变量。
- **get_typed()**：读取数据入口。实际例子：CombatResolver 通过 get_typed 获取最终攻击力，而不是直接读内部变量。
- **unregister_service()**：注销入口。实际例子：敌人死亡或场景卸载时从 CommandRouter 移除 receiver，避免命令发到无效节点。
- **clear()**：清理/重置入口。实际例子：切换存档、退出 run 或重启测试时调用，让 **ServiceRegistry** 清空自己的运行时缓存。

### 使用示例

```gdscript
ServiceRegistry.register_service("random", RandomService.new())
ServiceRegistry.register_service("events", EventRouter.new())
ServiceRegistry.register_service("content", ContentRegistry.new())

var random := ServiceRegistry.get_service("random") as RandomService
```

---

---

### 27.1 ServiceRegistry 使用示例

#### 详细实际用例

- 真实场景：游戏启动时，`GameBootstrap` 创建 `EventRouter`、`ContentRegistry`、`CommandRouter`、`RandomService`，并把它们注册到 `ServiceRegistry`。之后玩家攻击敌人时，`DealDamageEffect` 可以通过 `"events"` 找到事件路由器发出 `damage_applied`，而不需要知道事件路由器挂在哪个节点下面。
- 怎么使用：只注册真正全局、跨场景存在的服务；不要把某个具体敌人、某个房间宝箱、某个 UI 按钮注册进去。测试时可以把 `"ads"` 注册成 `AdServiceMock`，移动端发布时再换成真实广告服务。
- 验证重点：启动后调用 `has_service("events")`、`get_service("content")` 应该成功；缺失服务时应该有清晰错误，而不是空引用崩溃。
### 注册核心服务

```gdscript
func _ready() -> void:
    var events := EventRouter.new()
    var commands := CommandRouter.new()
    var content := ContentRegistry.new()
    var random := RandomService.new()
    var actions := ActionRunner.new()
    var effects := EffectExecutor.new()

    add_child(events)
    add_child(commands)
    add_child(content)
    add_child(actions)

    ServiceRegistry.register_service("events", events)
    ServiceRegistry.register_service("commands", commands)
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("random", random)
    ServiceRegistry.register_service("actions", actions)
    ServiceRegistry.register_service("effects", effects)
```

### 在任意系统中获取服务

```gdscript
func grant_reward(option: RewardOption) -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_domain_event(DomainEvent.create("reward_granted", "system", "player", {
            "reward_id": option.reward_id
        }))
```

---

---

---

## 2.2 GameBootstrap

### 概念说明

- 是什么：Mkit 的启动编排器。
- 负责什么：创建服务、注册服务、加载资源数据库、校验内容、初始化运行时系统并进入初始场景。
- 为什么需要：Godot 项目的启动顺序如果靠节点 ready 顺序隐式决定，很容易出现偶发 bug；Bootstrap 让启动过程可读、可测、可复现。

### 文件

`res://addons/mkit/kernel/bootstrap/game_bootstrap.gd`

### 职责

```text
1. 创建核心服务
2. 注册服务
3. 加载资源数据库
4. 校验 ContentRegistry
5. 加载存档或创建 profile
6. 进入 MainMenu 或 StartRun
```

### 接口

```gdscript
class_name GameBootstrap
extends Node

@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = "res://game/scenes/main_menu.tscn"

func _ready() -> void:
    boot()

func boot() -> void:
    _register_kernel_services()
    _load_content()
    _validate_content()
    _initialize_runtime_systems()
    _load_profile()
    _enter_initial_scene()

func _register_kernel_services() -> void:
    var events := EventRouter.new()
    var content := ContentRegistry.new()
    var random := RandomService.new()
    var time := TimeService.new()
    var action_runner := ActionRunner.new()
    var effect_executor := EffectExecutor.new()
    var command_router := CommandRouter.new()
    var scene_router := SceneRouter.new()
    var save_manager := SaveManager.new()
    var progression := ProgressionSystem.new()
    var object_pool := ObjectPool.new()

    add_child(events)
    add_child(content)
    add_child(action_runner)
    add_child(command_router)
    add_child(scene_router)
    add_child(save_manager)
    add_child(progression)
    add_child(object_pool)

    ServiceRegistry.register_service("events", events)
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("random", random)
    ServiceRegistry.register_service("time", time)
    ServiceRegistry.register_service("actions", action_runner)
    ServiceRegistry.register_service("effects", effect_executor)
    ServiceRegistry.register_service("commands", command_router)
    ServiceRegistry.register_service("scenes", scene_router)
    ServiceRegistry.register_service("save", save_manager)
    ServiceRegistry.register_service("progression", progression)
    ServiceRegistry.register_service("pool", object_pool)

func _load_content() -> void:
    var registry := ServiceRegistry.get_service("content") as ContentRegistry
    for db in resource_databases:
        registry.load_database(db)

func _validate_content() -> void:
    var registry := ServiceRegistry.get_service("content") as ContentRegistry
    var result := registry.validate_all()
    if not result.success:
        push_error("Content validation failed: %s" % result.errors)

func _initialize_runtime_systems() -> void:
    pass

func _load_profile() -> void:
    pass

func _enter_initial_scene() -> void:
    if initial_scene_path != "":
        var scene_router := ServiceRegistry.get_service("scenes") as SceneRouter
        if scene_router != null:
            scene_router.change_scene(initial_scene_path)
        else:
            get_tree().change_scene_to_file(initial_scene_path)
```

#### 字段说明
- **initial_scene_path**：资源或节点路径。例：用 initial_scene_path 指向场景或节点，方便在 Inspector 中配置。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**GameBootstrap** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **boot()**：公开 API。实际例子：外部系统通过它请求 **GameBootstrap** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_register_kernel_services()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_load_content()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_validate_content()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_initialize_runtime_systems()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_load_profile()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_enter_initial_scene()**：内部辅助函数。实际例子：由 **GameBootstrap** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.2 GameBootstrap 使用示例

#### 详细实际用例

- 真实场景：玩家打开游戏进入主菜单前，`GameBootstrap` 负责把所有基础服务准备好，加载物品/技能/敌人/房间数据库，检查有没有重复 ID，然后再切到 `main_menu.tscn`。
- 怎么使用：把它作为启动场景或 Autoload 的入口节点；在 Inspector 里配置 `resource_databases`，让它按固定顺序执行 `_register_kernel_services -> _load_content -> _validate_content -> _enter_initial_scene`。
- 验证重点：故意放一个重复的 `item_id`，启动时应该能在内容校验阶段报错；修复后才能进入初始场景。
### Main 场景挂载 GameBootstrap

```text
Main.tscn
  GameBootstrap
```

### Inspector 配置

```text
GameBootstrap.resource_databases = [
  res://game/content/items/item_database.tres,
  res://game/content/abilities/ability_database.tres,
  res://game/content/rooms/room_database.tres
]

GameBootstrap.initial_scene_path = "res://game/scenes/main_menu.tscn"
```

### 典型启动流程

```gdscript
func boot() -> void:
    _register_kernel_services()
    _load_content()
    _validate_content()
    _initialize_runtime_systems()
    _load_profile()
    _enter_initial_scene()
```

---

---

---

## 2.3 DomainEvent / EventRouter

### 概念说明

- 是什么：已经发生的玩法事实的通知层。
- 负责什么：发布 damage_applied、entity_died、inventory_changed、room_cleared、run_started 等事件，并保留最近事件供调试查看。
- 为什么需要：UI、音效、VFX、Analytics 和 Debug 都需要知道发生了什么，但不应该直接依赖 Combat、Inventory 或 Room 的内部实现。

### 设计原则

Event 是已经发生的事实，用过去式命名。

好的事件：

```text
damage_applied
entity_died
item_collected
inventory_changed
room_cleared
reward_selected
run_started
run_finished
```

不要用 event 来请求别人做事。

### DomainEvent

`res://addons/mkit/kernel/events/domain_event.gd`

```gdscript
class_name DomainEvent
extends RefCounted

var event_type: String = ""
var event_id: String = ""
var timestamp: float = 0.0
var source_id: String = ""
var target_id: String = ""
var payload: Dictionary = {}

static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> DomainEvent:
    var e := DomainEvent.new()
    e.event_type = type
    e.event_id = "%s_%d" % [type, Time.get_ticks_usec()]
    e.timestamp = Time.get_ticks_msec() / 1000.0
    e.source_id = source
    e.target_id = target
    e.payload = data
    return e
```

#### 字段说明
- **event_type**：事件类型。例：damage_applied、entity_died、room_cleared，用来让监听者决定是否响应。
- **event_id**：单次事件 ID。例：同一秒内可能有多次 damage_applied，event_id 让日志和回放能区分每一次。
- **timestamp**：发生时间。例：DebugOverlay 可以按时间排序最近事件，回放系统也能按时间重放命令。
- **source_id**：行为来源 ID。例：伤害事件里 source_id=player_001，Analytics 和仇恨系统就知道是谁造成了伤害。
- **target_id**：行为目标 ID。例：CastAbilityCommand 的 target_id=player_001 表示命令发给玩家实体处理，不是直接发给技能资源。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。
#### 函数使用场景
- **create()**：工厂方法。实际例子：掉落系统创建 ItemInstance 或 DomainEvent 时，用 create 保证 ID、时间戳和默认字段一次性设置完整。

### EventRouter

`res://addons/mkit/kernel/events/event_router.gd`

```gdscript
class_name EventRouter
extends Node

signal domain_event_emitted(event: DomainEvent)
signal damage_applied(result: DamageResult)
signal entity_died(entity_id: String, entity_ref: Node)
signal item_collected(item_instance: ItemInstance)
signal inventory_changed(owner_id: String)
signal room_cleared(room_id: String)
signal reward_selected(reward_id: String)
signal run_started(run_id: String, seed: int)
signal run_finished(run_id: String, result: String)

var recent_events: Array[DomainEvent] = []
var max_recent_events: int = 100

func emit_domain_event(event: DomainEvent) -> void:
    recent_events.append(event)
    if recent_events.size() > max_recent_events:
        recent_events.pop_front()
    domain_event_emitted.emit(event)

func emit_damage_applied(result: DamageResult) -> void:
    damage_applied.emit(result)
    emit_domain_event(DomainEvent.create(
        "damage_applied",
        _get_entity_id(result.source),
        _get_entity_id(result.target),
        result.to_debug_dict()
    ))

func emit_entity_died(entity_id: String, entity_ref: Node) -> void:
    entity_died.emit(entity_id, entity_ref)
    emit_domain_event(DomainEvent.create("entity_died", entity_id, "", {"entity_id": entity_id}))

func emit_inventory_changed(owner_id: String) -> void:
    inventory_changed.emit(owner_id)
    emit_domain_event(DomainEvent.create("inventory_changed", owner_id, "", {}))

func emit_item_collected(item_instance: ItemInstance, collector_id: String = "") -> void:
    item_collected.emit(item_instance)
    emit_domain_event(DomainEvent.create("item_collected", collector_id, "", {
        "item_id": item_instance.definition_id if item_instance != null else "",
        "quantity": item_instance.quantity if item_instance != null else 0,
        "instance_id": item_instance.instance_id if item_instance != null else ""
    }))

func emit_room_cleared(room_id: String) -> void:
    room_cleared.emit(room_id)
    emit_domain_event(DomainEvent.create("room_cleared", room_id, "", {}))

func emit_reward_selected(reward_id: String, source_id: String = "") -> void:
    reward_selected.emit(reward_id)
    emit_domain_event(DomainEvent.create("reward_selected", source_id, "", {
        "reward_id": reward_id
    }))

func emit_run_started(run_id: String, seed: int) -> void:
    run_started.emit(run_id, seed)
    emit_domain_event(DomainEvent.create("run_started", run_id, "", {
        "seed": seed
    }))

func emit_run_finished(run_id: String, result: String) -> void:
    run_finished.emit(run_id, result)
    emit_domain_event(DomainEvent.create("run_finished", run_id, "", {
        "result": result
    }))

func _get_entity_id(entity: Node) -> String:
    if entity == null:
        return ""
    var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
    if identity != null:
        return identity.entity_id
    return entity.name
```

#### 字段说明
- **recent_events**：最近事件列表。例：DebugOverlay 显示最近 damage_applied、entity_died、room_cleared，方便排查流程。
- **max_recent_events**：最近事件保留上限。例：只保留 100 条，避免长期运行后 Debug 数据无限增长。
#### 信号说明
- **domain_event_emitted**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **damage_applied**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **entity_died**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **item_collected**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **inventory_changed**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **room_cleared**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **reward_selected**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **run_started**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **run_finished**：当 **EventRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **emit_domain_event()**：事件发射入口。实际例子：HealthComponent 确认敌人死亡后通过 EventRouter 发出 entity_died。
- **emit_damage_applied()**：事件发射入口。实际例子：HealthComponent 应用 DamageResult 后发出 damage_applied。
- **emit_entity_died()**：事件发射入口。实际例子：HealthComponent 确认敌人死亡后通过 EventRouter 发出 entity_died。
- **emit_inventory_changed()**：事件发射入口。实际例子：InventoryController 添加或移除物品后发出 inventory_changed。
- **emit_item_collected()**：事件发射入口。实际例子：拾取物品成功进入背包后发出 item_collected。
- **emit_room_cleared()**：事件发射入口。实际例子：RoomController 检测所有敌人死亡后发出 room_cleared。
- **emit_reward_selected()**：事件发射入口。实际例子：玩家选择三选一奖励后发出 reward_selected。
- **emit_run_started()**：事件发射入口。实际例子：RunDirector 创建 RunState 后发出 run_started。
- **emit_run_finished()**：事件发射入口。实际例子：RunDirector 完成或失败一局后发出 run_finished。
- **_get_entity_id()**：内部辅助函数。实际例子：由 **EventRouter** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.3 DomainEvent 使用示例

#### 详细实际用例

- 真实场景：玩家一剑击中敌人后，战斗系统创建 `damage_applied` 事件，记录来源是 `player_001`，目标是 `goblin_002`，payload 里放最终伤害和是否暴击。
- 怎么使用：把它当作“发生过的事实记录”，不要用它请求别人做事。比如 `entity_died` 表示敌人已经死了，不是请求 HealthComponent 去杀死敌人。
- 验证重点：事件日志里同类型事件要有不同 `event_id` 和时间戳，DebugOverlay 能按顺序显示最近发生了什么。
### 创建一个通用事件

```gdscript
var event := DomainEvent.create(
    "item_collected",
    "player_001",
    "",
    {
        "item_id": "item.sword_iron",
        "quantity": 1
    }
)
```

### 通过 EventRouter 发出事件

```gdscript
var events := ServiceRegistry.get_service("events") as EventRouter
if events != null:
    events.emit_domain_event(event)
```

---

---

---

### 27.4 EventRouter 使用示例

#### 详细实际用例

- 真实场景：`HealthComponent` 确认敌人死亡后调用 `EventRouter.emit_entity_died()`；`RoomController` 监听它减少活跃敌人数，`FeedbackSystem` 监听它播放死亡特效，`AnalyticsService` 监听它记录击杀。
- 怎么使用：核心玩法系统发出过去式事件，表现层和统计层订阅事件。Combat 不直接播放音效，Room 不直接读取 Combat 内部状态。
- 验证重点：一个 `entity_died` 能同时驱动房间清理、掉落生成和死亡反馈；移除某个监听者不应该影响其他监听者。
### 监听伤害事件

```gdscript
func _ready() -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    events.damage_applied.connect(_on_damage_applied)
    events.entity_died.connect(_on_entity_died)

func _on_damage_applied(result: DamageResult) -> void:
    print("Damage applied: ", result.final_amount)

func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
    print("Entity died: ", entity_id)
```

### 发出房间清理事件

```gdscript
func on_all_enemies_dead() -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_room_cleared("room_001")
```

---

---

---

## 2.4 GameCommand

### 概念说明

- 是什么：表示“意图”的数据对象。
- 负责什么：承载 move、attack、cast_ability、interact、equip_item、select_reward 等来自玩家、AI、教程、自动测试或未来网络输入的请求。
- 为什么需要：把意图和效果分开后，玩家输入和 AI 可以走同一条行为链路，测试也能直接发送命令验证系统。

### 文件

`res://addons/mkit/kernel/commands/game_command.gd`

### 接口

```gdscript
class_name GameCommand
extends RefCounted

var command_id: String = ""
var command_type: String = ""
var source_id: String = ""
var target_id: String = ""
var timestamp: float = 0.0
var priority: int = 0
var payload: Dictionary = {}
var consumed: bool = false

static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> GameCommand:
    var cmd := GameCommand.new()
    cmd.command_type = type
    cmd.command_id = "%s_%d" % [type, Time.get_ticks_usec()]
    cmd.source_id = source
    cmd.target_id = target
    cmd.timestamp = Time.get_ticks_msec() / 1000.0
    cmd.payload = data
    return cmd

func mark_consumed() -> void:
    consumed = true

func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
    if payload.has(key):
        return payload[key]
    return default_value

func get_string(key: String, default_value: String = "") -> String:
    if payload.has(key):
        return str(payload[key])
    return default_value

func get_float(key: String, default_value: float = 0.0) -> float:
    if payload.has(key):
        return float(payload[key])
    return default_value
```

#### 字段说明
- **command_id**：单次命令 ID。例：玩家连续点两次攻击时，两个 attack 命令需要能在 debug history 里分开追踪。
- **command_type**：命令类型。例：move、attack、cast_ability，StateMachine 根据它决定当前状态能不能处理。
- **source_id**：行为来源 ID。例：伤害事件里 source_id=player_001，Analytics 和仇恨系统就知道是谁造成了伤害。
- **target_id**：行为目标 ID。例：CastAbilityCommand 的 target_id=player_001 表示命令发给玩家实体处理，不是直接发给技能资源。
- **timestamp**：发生时间。例：DebugOverlay 可以按时间排序最近事件，回放系统也能按时间重放命令。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。
- **consumed**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
#### 函数使用场景
- **create()**：工厂方法。实际例子：掉落系统创建 ItemInstance 或 DomainEvent 时，用 create 保证 ID、时间戳和默认字段一次性设置完整。
- **mark_consumed()**：标记命令已被处理。实际例子：StateMachine 成功处理 attack 命令后标记 consumed，避免同一命令被后续系统重复处理。
- **get_vector2()**：读取数据入口。实际例子：CombatResolver 通过 get_vector2 获取最终攻击力，而不是直接读内部变量。
- **get_string()**：读取数据入口。实际例子：CombatResolver 通过 get_string 获取最终攻击力，而不是直接读内部变量。
- **get_float()**：读取数据入口。实际例子：CombatResolver 通过 get_float 获取最终攻击力，而不是直接读内部变量。

### Built-in Commands

`res://addons/mkit/kernel/commands/builtin_commands.gd`

```gdscript
class_name BuiltinCommands
extends Object

const MOVE := "move"
const STOP_MOVE := "stop_move"
const ATTACK := "attack"
const CAST_ABILITY := "cast_ability"
const DASH := "dash"
const INTERACT := "interact"
const SELECT_REWARD := "select_reward"
const OPEN_INVENTORY := "open_inventory"
const CLOSE_INVENTORY := "close_inventory"
const EQUIP_ITEM := "equip_item"
const UNEQUIP_ITEM := "unequip_item"
const PAUSE := "pause"
const RESUME := "resume"
```

---

---

### 27.5 GameCommand 使用示例

#### 详细实际用例

- 真实场景：玩家按攻击键时，输入层创建 `GameCommand.create("attack", "player_001", "player_001", {"direction": Vector2.RIGHT})`。敌人 AI 想攻击玩家时，也创建同类型命令，只是 source/target 不同。
- 怎么使用：把命令当作“想做什么”的数据，不要在命令里直接扣血、生成掉落或切 UI。命令进入 `CommandReceiver` 后，由当前状态决定能不能处理。
- 验证重点：同一个 `attack` 命令从玩家输入、AI 或自动测试发出时，都应该走同一套状态机和 Action 流程。
### 玩家输入创建移动命令

```gdscript
func _physics_process(delta: float) -> void:
    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if dir != Vector2.ZERO:
        var cmd := GameCommand.create(
            BuiltinCommands.MOVE,
            "player_001",
            "player_001",
            {"direction": dir}
        )
        var router := ServiceRegistry.get_service("commands") as CommandRouter
        router.dispatch(cmd)
```

### 创建技能释放命令

```gdscript
func cast_fireball() -> void:
    var cmd := GameCommand.create(
        BuiltinCommands.CAST_ABILITY,
        "player_001",
        "player_001",
        {
            "ability_id": "ability.fireball_basic",
            "direction": Vector2.RIGHT
        }
    )
    ServiceRegistry.get_service("commands").dispatch(cmd)
```

---

---

---

### 27.6 BuiltinCommands 使用示例

#### 详细实际用例

- 真实场景：输入层、AI 层、状态机都用 `BuiltinCommands.ATTACK`，而不是有人写 `"attack"`、有人写 `"basic_attack"`、有人写 `"Attack"`。
- 怎么使用：所有通用命令名集中在这里；新增 `OPEN_MAP` 或 `SWAP_WEAPON` 这类基础命令时先放进常量表，再让 receiver 支持它。
- 验证重点：重命名命令时只改常量和处理点，项目里不应该散落大量裸字符串。
```gdscript
match command.command_type:
    BuiltinCommands.MOVE:
        _handle_move(command)
    BuiltinCommands.ATTACK:
        _handle_attack(command)
    BuiltinCommands.CAST_ABILITY:
        _handle_cast(command)
    BuiltinCommands.INTERACT:
        _handle_interact(command)
```

---

---

---

## 2.5 CommandReceiver / CommandRouter

### 概念说明

- 是什么：命令生产者和命令消费者之间的路由层。
- 负责什么：根据 target_id 找到接收者，投递命令，记录历史，并交给 StateMachine 或控制器处理。
- 为什么需要：没有命令路由时，Input 和 AI 往往直接调用具体节点方法，系统会快速变成强耦合。

### CommandReceiver

`res://addons/mkit/kernel/commands/command_receiver.gd`

```gdscript
class_name CommandReceiver
extends Node

@export var receiver_id: String = ""
@export var auto_register: bool = true

var owner_entity: Node = null
var state_machine: StateMachine = null
var command_history: Array[GameCommand] = []
var max_history: int = 20

func _ready() -> void:
    owner_entity = owner
    state_machine = owner.get_node_or_null("StateMachine") as StateMachine
    # Derive a stable receiver_id from EntityIdentity when it was not set in the
    # Inspector. Spawned enemies get their entity_id at runtime, so without this
    # they would register under "" and AI commands (dispatched to the entity_id)
    # would never route. Place EntityIdentity before CommandReceiver in the scene
    # so its _ready (and id assignment) runs first.
    if receiver_id == "":
        var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
        if identity != null:
            receiver_id = identity.entity_id
    if auto_register:
        var router := ServiceRegistry.get_service("commands") as CommandRouter
        if router != null:
            router.register_receiver(receiver_id, self)

func receive_command(command: GameCommand) -> bool:
    _record_command(command)

    if state_machine != null:
        var handled := state_machine.handle_command(command)
        if handled:
            command.mark_consumed()
            return true

    return handle_unhandled_command(command)

func handle_unhandled_command(command: GameCommand) -> bool:
    return false

func _record_command(command: GameCommand) -> void:
    command_history.append(command)
    if command_history.size() > max_history:
        command_history.pop_front()
```

#### 字段说明
- **receiver_id**：命令接收者 ID。例：player_001 的 CommandReceiver 注册后，CommandRouter 才能把攻击命令投递给玩家。
- **auto_register**：是否自动注册到路由器。例：敌人生成后自动注册 receiver，就能立刻接收 AI 命令。
- **owner_entity**：拥有该组件或状态机的实体。例：PlayerMoveState 需要通过 owner_entity 读取 StatsComponent 并推动 CharacterBody2D。
- **state_machine**：所属状态机引用。例：AttackState 完成后通过 state_machine 请求回到 Idle。
- **command_history**：最近命令历史。例：玩家卡住时可以看到最后收到的是 dash 还是 attack。
- **max_history**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**CommandReceiver** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **receive_command()**：命令投递入口。实际例子：PlayerInputReader 把 attack 命令 dispatch 给 player_001，AI 也可以用同样方式驱动敌人。
- **handle_unhandled_command()**：公开 API。实际例子：外部系统通过它请求 **CommandReceiver** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_record_command()**：内部辅助函数。实际例子：由 **CommandReceiver** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

### CommandRouter

`res://addons/mkit/kernel/commands/command_router.gd`

```gdscript
class_name CommandRouter
extends Node

signal command_dispatched(command: GameCommand)
signal command_failed(command: GameCommand, reason: String)

var _receivers: Dictionary = {}

func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void:
    assert(receiver_id != "")
    assert(receiver != null)
    _receivers[receiver_id] = receiver

func unregister_receiver(receiver_id: String) -> void:
    _receivers.erase(receiver_id)

func dispatch(command: GameCommand) -> bool:
    command_dispatched.emit(command)

    if command.target_id == "":
        command_failed.emit(command, "Missing target_id")
        return false

    if not _receivers.has(command.target_id):
        command_failed.emit(command, "No receiver for target_id: %s" % command.target_id)
        return false

    var receiver := _receivers[command.target_id] as CommandReceiver
    var handled := receiver.receive_command(command)
    if not handled:
        command_failed.emit(command, "Receiver did not handle command: %s" % command.command_type)
    return handled

func broadcast(command: GameCommand, receiver_ids: Array[String]) -> int:
    var handled_count := 0
    for id in receiver_ids:
        var cloned := GameCommand.create(command.command_type, command.source_id, id, command.payload)
        if dispatch(cloned):
            handled_count += 1
    return handled_count
```

#### 信号说明
- **command_dispatched**：当 **CommandRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **command_failed**：当 **CommandRouter** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **register_receiver()**：注册入口。实际例子：GameBootstrap 启动时把 EventRouter 注册为 events 服务。
- **unregister_receiver()**：注销入口。实际例子：敌人死亡或场景卸载时从 CommandRouter 移除 receiver，避免命令发到无效节点。
- **dispatch()**：命令投递入口。实际例子：PlayerInputReader 把 attack 命令 dispatch 给 player_001，AI 也可以用同样方式驱动敌人。
- **broadcast()**：命令投递入口。实际例子：PlayerInputReader 把 attack 命令 dispatch 给 player_001，AI 也可以用同样方式驱动敌人。

---

---

### 27.7 CommandReceiver 使用示例

#### 详细实际用例

- 真实场景：`Player.tscn` 上挂 `CommandReceiver(receiver_id="player_001")`。输入层发来的 move/attack/cast 命令先到这里，再交给玩家 `StateMachine`。
- 怎么使用：每个需要接收命令的实体或系统都注册自己的 receiver_id。`receive_command()` 先记录历史，再让状态机处理，处理不了时走 `handle_unhandled_command()`。
- 验证重点：DebugOverlay 能看到玩家最近收到的命令；敌人死亡或场景卸载后 receiver 应该注销，避免命令投递到失效节点。
### Player 场景结构

```text
Player.tscn
  CharacterBody2D
    EntityIdentity
    CommandReceiver
    StateMachine
    Components
    Controllers
```

### 配置 CommandReceiver

```gdscript
func _ready() -> void:
    $CommandReceiver.receiver_id = $EntityIdentity.entity_id
```

### 自定义 fallback command 处理

```gdscript
class_name PlayerCommandReceiver
extends CommandReceiver

func handle_unhandled_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.OPEN_INVENTORY:
        var ui := ServiceRegistry.get_service("ui") as UIManager
        ui.open_screen("inventory")
        return true
    return false
```

---

---

---

### 27.8 CommandRouter 使用示例

#### 详细实际用例

- 真实场景：`PlayerInputReader` 不直接调用 `$Player.attack()`，而是把 `attack` 命令交给 `CommandRouter.dispatch()`，由 router 根据 `target_id="player_001"` 找到玩家的 `CommandReceiver`。
- 怎么使用：单目标命令用 `dispatch()`，群体命令或广播测试可以用 `broadcast()`。失败时通过 `command_failed` 信号暴露原因。
- 验证重点：目标 ID 不存在时应得到 “No receiver” 错误；目标存在但当前状态不能处理时应得到 “Receiver did not handle command”。
### 注册 Receiver

```gdscript
func _ready() -> void:
    var router := ServiceRegistry.get_service("commands") as CommandRouter
    router.register_receiver("player_001", $Player/CommandReceiver)
```

### 派发攻击命令

```gdscript
var attack_cmd := GameCommand.create(
    BuiltinCommands.ATTACK,
    "player_001",
    "player_001",
    {"direction": Vector2.RIGHT}
)

var handled := router.dispatch(attack_cmd)
if not handled:
    print("Attack command was not handled")
```

---

---

---

## 2.6 GameplayContext

### 概念说明

- 是什么：一次玩法解析所需信息的上下文对象。
- 负责什么：携带 source、target、position、direction、ability_id、item_id、room_id、run_id、tags、amount 和 payload。
- 为什么需要：它把散落的 Dictionary key 收拢起来，减少拼错 key 或漏传数据导致的 bug。

### 文件

`res://addons/mkit/kernel/context/gameplay_context.gd`

### 接口

```gdscript
class_name GameplayContext
extends RefCounted

var source: Node = null
var target: Node = null
var instigator: Node = null
var ability_id: String = ""
var item_id: String = ""
var status_id: String = ""
var room_id: String = ""
var run_id: String = ""
var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var amount: float = 0.0
var tags: Array[String] = []
var payload: Dictionary = {}

static func from_command(command: GameCommand, source_node: Node = null, target_node: Node = null) -> GameplayContext:
    var ctx := GameplayContext.new()
    ctx.source = source_node
    ctx.target = target_node
    ctx.payload = command.payload.duplicate(true)
    ctx.direction = command.get_vector2("direction", Vector2.ZERO)
    ctx.position = command.get_vector2("position", Vector2.ZERO)
    ctx.ability_id = command.get_string("ability_id", "")
    ctx.item_id = command.get_string("item_id", "")
    return ctx

func with_source(node: Node) -> GameplayContext:
    source = node
    return self

func with_target(node: Node) -> GameplayContext:
    target = node
    return self

func with_payload_value(key: String, value) -> GameplayContext:
    payload[key] = value
    return self

func get_payload_value(key: String, default_value = null):
    if payload.has(key):
        return payload[key]
    return default_value

func has_tag(tag: String) -> bool:
    return tags.has(tag)
```

#### 字段说明
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **instigator**：真正发起者。例：召唤物造成伤害时 source 可以是召唤物，instigator 是玩家，用来归属击杀奖励。
- **ability_id**：技能定义 ID。例：ability.fireball_basic 让 AbilityController 找到火球定义并读取冷却、消耗和效果。
- **item_id**：物品定义 ID。例：item.potion_small 用于从 ContentRegistry 找到药水定义。
- **status_id**：状态定义 ID。例：status.burn 用于创建燃烧状态实例。
- **room_id**：房间定义或运行时房间 ID。例：room.dungeon_small_01 用于清房间、奖励和存档恢复。
- **run_id**：一局 run 的 ID。例：Analytics 可以把所有 room_cleared 和 reward_selected 归到同一局。
- **position**：世界位置。例：SpawnSceneEffect 用 position 决定投射物或掉落物生成在哪里。
- **direction**：方向。例：玩家按右方向释放火球，direction=Vector2.RIGHT。
- **amount**：通用数值。例：HealEffect 可以把 amount 当治疗量，RewardEffect 可以把 amount 当金币数量。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。
#### 函数使用场景
- **from_command()**：从命令构造上下文。实际例子：CastAbilityCommand 到达玩家后，用命令 payload 创建 GameplayContext 或 ActionContext。
- **with_source()**：公开 API。实际例子：外部系统通过它请求 **GameplayContext** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **with_target()**：公开 API。实际例子：外部系统通过它请求 **GameplayContext** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **with_payload_value()**：公开 API。实际例子：外部系统通过它请求 **GameplayContext** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **get_payload_value()**：读取数据入口。实际例子：CombatResolver 通过 get_payload_value 获取最终攻击力，而不是直接读内部变量。
- **has_tag()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。

---

---

### 27.9 GameplayContext 使用示例

#### 详细实际用例

- 真实场景：玩家释放火球时，`GameplayContext` 记录 source=玩家、target=最近敌人、ability_id=`ability.fireball_basic`、direction=鼠标方向。后续 Condition、Action、Effect 都读同一个上下文。
- 怎么使用：不要在 Effect 之间传一堆裸 Dictionary；先从命令创建 Context，再在必要时补充 source、target、position、run_id 等字段。
- 验证重点：火球伤害、燃烧状态、VFX 生成和 Analytics 都能从同一个 Context 追踪来源和目标。
### 从 Command 创建 Context

```gdscript
func handle_cast_command(command: GameCommand) -> void:
    var context := GameplayContext.from_command(command, owner, null)
    context.ability_id = command.get_string("ability_id")
    context.source = owner
    context.target = _find_target_in_front()

    var ability_controller := owner.get_node("Controllers/AbilityController") as AbilityController
    ability_controller.cast(context.ability_id, context)
```

### 手动创建 Context

```gdscript
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy
ctx.position = enemy.global_position
ctx.direction = (enemy.global_position - player.global_position).normalized()
ctx.payload["room_id"] = "room_001"
```

---

---

---

## 2.7 Blackboard

### 概念说明

- 是什么：行为系统的短期共享记忆。
- 负责什么：保存移动方向、当前目标、临时计时器、AI 决策值、状态间共享数据等。
- 为什么需要：State、Action、AI 经常需要共享少量运行时数据，但不应该互相直接持有大量引用。

### 用途

给 AI、HFSM、Action 临时共享上下文，不能替代正式状态对象。

`res://addons/mkit/kernel/context/blackboard.gd`

```gdscript
class_name Blackboard
extends RefCounted

var _data: Dictionary = {}

func set_value(key: String, value) -> void:
    _data[key] = value

func get_value(key: String, default_value = null):
    if _data.has(key):
        return _data[key]
    return default_value

func has_value(key: String) -> bool:
    return _data.has(key)

func erase_value(key: String) -> void:
    _data.erase(key)

func clear() -> void:
    _data.clear()

func to_debug_dict() -> Dictionary:
    return _data.duplicate(true)
```

#### 函数使用场景
- **set_value()**：写入或配置入口。实际例子：测试场景通过 set_value 设置黑板值或初始化运行时状态。
- **get_value()**：读取数据入口。实际例子：CombatResolver 通过 get_value 获取最终攻击力，而不是直接读内部变量。
- **has_value()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **erase_value()**：公开 API。实际例子：外部系统通过它请求 **Blackboard** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **clear()**：清理/重置入口。实际例子：切换存档、退出 run 或重启测试时调用，让 **Blackboard** 清空自己的运行时缓存。
- **to_debug_dict()**：公开 API。实际例子：外部系统通过它请求 **Blackboard** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

---

### 27.10 Blackboard 使用示例

#### 详细实际用例

- 真实场景：玩家移动状态把当前输入方向存到 Blackboard 的 `move_direction`；攻击状态读取 `last_facing_direction` 来决定挥剑方向；AI 把当前目标存到 `target`。
- 怎么使用：存短期行为数据，不存永久角色属性。比如 “当前追踪目标” 适合放 Blackboard，“最大生命值” 应该在 Stats/Health 里。
- 验证重点：状态切换后需要保留的数据仍可读取；离开行为树或重置实体时可以 clear，避免旧目标污染新行为。
### 在 MoveState 中写入移动方向

```gdscript
func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.MOVE:
        blackboard.set_value("move_direction", command.get_vector2("direction"))
        return true
    return false
```

### 在 physics_update 中读取方向

```gdscript
func physics_update(delta: float) -> void:
    var direction := blackboard.get_value("move_direction", Vector2.ZERO)
    var stats := owner_entity.get_node("Components/StatsComponent") as StatsComponent
    var speed := stats.get_stat_value("move_speed", 160.0)
    owner_entity.velocity = direction * speed
    owner_entity.move_and_slide()
```

---

---

---

## 2.8 RandomService

### 概念说明

- 是什么：统一随机数服务。
- 负责什么：保存 run seed，提供 randf、randi_range、weighted_pick 等确定性随机 API。
- 为什么需要：战斗暴击、掉落、奖励和地牢生成都需要随机；集中在一个服务里才能复现 bug、写测试和保存/恢复 run。

`res://addons/mkit/kernel/services/random_service.gd`

```gdscript
class_name RandomService
extends RefCounted

var seed_value: int = 0
var rng := RandomNumberGenerator.new()

func set_seed(value: int) -> void:
    seed_value = value
    rng.seed = value

func randomize_seed() -> int:
    rng.randomize()
    seed_value = rng.seed
    return seed_value

func randf() -> float:
    return rng.randf()

func randi_range(from: int, to: int) -> int:
    return rng.randi_range(from, to)

func randf_range(from: float, to: float) -> float:
    return rng.randf_range(from, to)

func chance(probability: float) -> bool:
    return randf() < clamp(probability, 0.0, 1.0)

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
```

#### 字段说明
- **seed_value**：当前随机种子。例：RunState 保存 seed_value 后，重新进入同一局可以复现房间图和掉落。
#### 函数使用场景
- **set_seed()**：写入随机种子。实际例子：RunDirector.start_run 创建 seed 后设置到 RandomService。
- **randomize_seed()**：生成随机种子。实际例子：新开一局时生成一个未指定 seed。
- **randf()**：返回 0 到 1 的浮点随机数。实际例子：CombatResolver 用它判断暴击。
- **randi_range()**：返回整数区间随机值。实际例子：LootSystem 掷掉落数量。
- **randf_range()**：返回浮点区间随机值。实际例子：VFXSpawner 给粒子轻微随机偏移。
- **chance()**：概率判定。实际例子：状态效果按 30% 概率触发。
- **weighted_pick()**：权重选择。实际例子：RewardSystem 从候选奖励池中按权重选出选项。

---

### 27.83 RandomService 使用示例

#### 详细实际用例

- 真实场景：玩家开始 run 时生成 seed=12345；DungeonGenerator、LootSystem、RewardSystem 都从 RandomService 取随机，因此同一 seed 可以复现同一条核心流程。
- 怎么使用：所有玩法随机都通过 `"random"` 服务；不要在战斗、掉落或生成器里直接调用全局 `randf()`。
- 验证重点：固定 seed 下，房间图、暴击序列和奖励候选在测试中可复现。

```gdscript
var random := ServiceRegistry.get_service("random") as RandomService
random.set_seed(12345)

if random.chance(0.25):
    print("Critical roll succeeded")
```

---

---

---

## 2.9 TimeService

### 概念说明

- 是什么：玩法时间的统一包装。
- 负责什么：提供 scaled/unscaled delta、暂停状态和时间缩放，不直接替代 Godot 的 Time 单例。
- 为什么需要：Action、状态效果、AI 思考和 UI 动画对暂停的要求不同；统一服务可以避免暂停菜单打开时战斗和冷却继续跑。

`res://addons/mkit/kernel/services/time_service.gd`

```gdscript
class_name TimeService
extends RefCounted

var paused: bool = false
var gameplay_time_scale: float = 1.0
var elapsed_gameplay_time: float = 0.0

func set_paused(value: bool) -> void:
    paused = value

func set_gameplay_time_scale(value: float) -> void:
    gameplay_time_scale = max(0.0, value)

func get_scaled_delta(delta: float) -> float:
    if paused:
        return 0.0
    return delta * gameplay_time_scale

func advance(delta: float) -> float:
    var scaled := get_scaled_delta(delta)
    elapsed_gameplay_time += scaled
    return scaled

func get_unix_time() -> int:
    return Time.get_unix_time_from_system()
```

#### 字段说明
- **paused**：玩法暂停标记。例：奖励选择 UI 打开时暂停 gameplay Action，但 UI 仍可响应输入。
- **gameplay_time_scale**：玩法时间倍率。例：子弹时间可以把 gameplay_time_scale 设为 0.25。
- **elapsed_gameplay_time**：已推进的玩法时间。例：DebugOverlay 显示从 run 开始到当前房间清理用了多久。
#### 函数使用场景
- **set_paused()**：设置暂停状态。实际例子：UIManager 打开 modal screen 时暂停 gameplay。
- **set_gameplay_time_scale()**：设置时间倍率。实际例子：慢动作奖励或命中特效短暂降低玩法时间。
- **get_scaled_delta()**：读取缩放后的 delta。实际例子：ActionRunner 用它更新可暂停 Action。
- **advance()**：推进玩法时间。实际例子：RunDirector 每帧累计本局用时。
- **get_unix_time()**：读取系统时间。实际例子：SaveManager 写入存档时间戳。

---

### 27.84 TimeService 使用示例

#### 详细实际用例

- 真实场景：打开暂停菜单时，UIManager 调用 `time.set_paused(true)`；ActionRunner 和 StatusEffectController 使用 scaled delta 后，攻击前摇、燃烧 tick 和 AI 思考都停止。
- 怎么使用：玩法时间用 TimeService，真实世界时间如存档 timestamp 仍可读 Godot Time。
- 验证重点：暂停后冷却不减少、状态不 tick；关闭菜单后从原进度继续。

```gdscript
var time := ServiceRegistry.get_service("time") as TimeService
time.set_paused(true)

func _process(delta: float) -> void:
    var scaled_delta := time.advance(delta)
    print("Gameplay advanced by: ", scaled_delta)
```

---

---

---

## 2.10 SceneRouter

### 概念说明

- 是什么：场景切换服务。
- 负责什么：统一执行 change_scene、reload、回到主菜单等场景流，并发出切换信号。
- 为什么需要：Bootstrap、RunDirector、死亡流程和 UI 都可能需要换场景；如果到处直接调用 `get_tree().change_scene_to_file()`，存档、淡入淡出和清理顺序会很难统一。

`res://addons/mkit/kernel/services/scene_router.gd`

```gdscript
class_name SceneRouter
extends Node

signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal scene_change_failed(scene_path: String, reason: String)

var current_scene_path: String = ""
var transition_locked: bool = false

func change_scene(scene_path: String) -> bool:
    if transition_locked:
        scene_change_failed.emit(scene_path, "transition_locked")
        return false
    if scene_path == "":
        scene_change_failed.emit(scene_path, "empty_scene_path")
        return false

    transition_locked = true
    scene_change_requested.emit(scene_path)
    var error := get_tree().change_scene_to_file(scene_path)
    transition_locked = false

    if error != OK:
        scene_change_failed.emit(scene_path, "error_%d" % error)
        return false

    current_scene_path = scene_path
    scene_changed.emit(scene_path)
    return true

func reload_current_scene() -> bool:
    if current_scene_path == "":
        return false
    return change_scene(current_scene_path)
```

#### 字段说明
- **current_scene_path**：当前场景路径。例：死亡后 reload_current_scene 可以重进当前 run 测试场景。
- **transition_locked**：切换锁。例：避免奖励选择和死亡流程同一帧重复切场景。
#### 信号说明
- **scene_change_requested**：请求切换前发出。实际例子：FeedbackSystem 可以播放淡出或记录 Debug trace。
- **scene_changed**：切换成功后发出。实际例子：Bootstrap 完成进入 MainMenu 后记录当前场景。
- **scene_change_failed**：切换失败时发出。实际例子：scene_path 配错时 UI 显示错误或测试失败。
#### 函数使用场景
- **change_scene()**：切换场景入口。实际例子：RunDirector 结束 run 后回到结算界面。
- **reload_current_scene()**：重载当前场景。实际例子：Debug 菜单快速重开当前 vertical slice。

---

### 27.85 SceneRouter 使用示例

#### 详细实际用例

- 真实场景：GameBootstrap 启动完服务和内容后，不直接换场景，而是调用 SceneRouter 进入 `main_menu.tscn`；后续 RunDirector 也通过同一个入口进入 run 场景或结算界面。
- 怎么使用：跨场景流走 `"scenes"` 服务；房间内部生成敌人或 UI 弹窗不使用 SceneRouter。
- 验证重点：同一帧多次切场景只执行一次；失败场景路径有明确错误。

```gdscript
var scenes := ServiceRegistry.get_service("scenes") as SceneRouter
scenes.change_scene("res://game/scenes/main_menu.tscn")
```

---

---

---

## 2.11 ObjectPool

### 概念说明

- 是什么：可复用场景实例池。
- 负责什么：预热、取出、归还投射物、伤害数字、VFX 等短生命周期节点。
- 为什么需要：动作 RPG 中投射物和特效频繁生成销毁；对象池能降低卡顿，同时保持生成逻辑不散落在各模块里。

`res://addons/mkit/kernel/services/object_pool.gd`

```gdscript
class_name ObjectPool
extends Node

var _pools: Dictionary = {} # scene_path -> Array[Node]

func warmup(scene_path: String, count: int, parent: Node = null) -> void:
    for i in range(count):
        var node := _instantiate(scene_path)
        if node == null:
            return
        _deactivate(node)
        if parent != null:
            parent.add_child(node)
        release(scene_path, node)

func acquire(scene_path: String, parent: Node = null) -> Node:
    var pool: Array = _pools.get(scene_path, [])
    var node: Node = null
    if not pool.is_empty():
        node = pool.pop_back()
    else:
        node = _instantiate(scene_path)
    _pools[scene_path] = pool

    if node != null:
        if parent != null and node.get_parent() != parent:
            if node.get_parent() != null:
                node.get_parent().remove_child(node)
            parent.add_child(node)
        _activate(node)
    return node

func release(scene_path: String, node: Node) -> void:
    if node == null:
        return
    _deactivate(node)
    if not _pools.has(scene_path):
        _pools[scene_path] = []
    var pool: Array = _pools[scene_path]
    pool.append(node)
    _pools[scene_path] = pool

func clear_pool(scene_path: String) -> void:
    if not _pools.has(scene_path):
        return
    for node in _pools[scene_path]:
        if node is Node:
            node.queue_free()
    _pools.erase(scene_path)

func _instantiate(scene_path: String) -> Node:
    var scene := load(scene_path) as PackedScene
    if scene == null:
        push_error("ObjectPool missing scene: %s" % scene_path)
        return null
    return scene.instantiate()

func _activate(node: Node) -> void:
    node.process_mode = Node.PROCESS_MODE_INHERIT
    if "on_pool_acquired" in node:
        node.on_pool_acquired()

func _deactivate(node: Node) -> void:
    node.process_mode = Node.PROCESS_MODE_DISABLED
    if "on_pool_released" in node:
        node.on_pool_released()
```

#### 函数使用场景
- **warmup()**：预热对象池。实际例子：进入战斗房前预创建 20 个伤害数字。
- **acquire()**：取出实例。实际例子：SpawnSceneEffect 获取一个 projectile 场景实例。
- **release()**：归还实例。实际例子：投射物命中或超时后回到池里。
- **clear_pool()**：清理池。实际例子：退出 run 时释放该 run 的临时 VFX 和 projectile。
- **_instantiate()**：内部实例化。实际例子：池为空时加载 PackedScene 创建节点。
- **_activate()**：内部激活。实际例子：取出节点时恢复 process 并调用可选回调。
- **_deactivate()**：内部停用。实际例子：归还节点时暂停 process 并隐藏或重置状态。

---

### 27.86 ObjectPool 使用示例

#### 详细实际用例

- 真实场景：火球技能频繁生成 projectile，SpawnSceneEffect 先从 ObjectPool acquire；火球命中敌人后调用 release，避免每次释放都加载和销毁场景。
- 怎么使用：短生命周期、高频对象用池；持久实体如玩家、房间、Boss 不放进通用池。
- 验证重点：归还后节点不会继续碰撞或播放旧动画；再次 acquire 时位置、方向和状态会被重新设置。

```gdscript
var pool := ServiceRegistry.get_service("pool") as ObjectPool
var projectile := pool.acquire("res://game/projectiles/fireball.tscn", $Projectiles)
projectile.global_position = player.global_position
projectile.direction = Vector2.RIGHT
```

---

---

---

## 2.12 DebugOverlay

### 概念说明

- 是什么：运行时调试叠层（CanvasLayer）。
- 负责什么：显示当前被观察实体的 HFSM 状态路径、HP、最近一次命令，以及 EventRouter 的最近事件。
- 为什么需要：Phase 0 验证（“DebugOverlay shows current state”）和后续排查 命令→状态→动作→效果→事件 链路都要求“可见的状态”。它不是 autoload：由 GameBootstrap 或 Main 场景创建并注册为 `debug` 服务（class_name 不与任何 autoload 冲突）。

`res://addons/mkit/kernel/debug/debug_overlay.gd`

```gdscript
class_name DebugOverlay
extends CanvasLayer

@export var watch_entity_path: NodePath
@export var visible_on_start: bool = true

var _label: Label = null
var _events: EventRouter = null

func _ready() -> void:
    _label = Label.new()
    add_child(_label)
    visible = visible_on_start
    if ServiceRegistry.has_service("events"):
        _events = ServiceRegistry.get_service("events") as EventRouter
    if not ServiceRegistry.has_service("debug"):
        ServiceRegistry.register_service("debug", self)

func _process(_delta: float) -> void:
    if visible:
        _label.text = _build_text()

func toggle() -> void:
    visible = not visible

func _build_text() -> String:
    var lines: Array[String] = []
    var entity := get_node_or_null(watch_entity_path)
    if entity != null:
        var sm := entity.get_node_or_null("StateMachine") as StateMachine
        if sm != null:
            lines.append("State: %s" % sm.get_current_path())
            if sm.last_failed_transition_reason != "":
                lines.append("Last failed transition: %s" % sm.last_failed_transition_reason)
        var receiver := entity.get_node_or_null("CommandReceiver") as CommandReceiver
        if receiver != null and not receiver.command_history.is_empty():
            lines.append("Last command: %s" % receiver.command_history[-1].command_type)
        var health := entity.get_node_or_null("Components/HealthComponent") as HealthComponent
        if health != null:
            lines.append("HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()])
    if _events != null and not _events.recent_events.is_empty():
        var recent := _events.recent_events.slice(max(0, _events.recent_events.size() - 5), _events.recent_events.size())
        var names: Array[String] = []
        for e in recent:
            names.append(e.event_type)
        lines.append("Recent events: %s" % ", ".join(names))
    return "\n".join(lines)
```

#### 字段说明
- **watch_entity_path**：要观察的实体（通常是玩家）。
- **visible_on_start**：是否启动即显示，可用快捷键 toggle。

#### 函数使用场景
- **_ready()**：创建 Label、缓存 EventRouter，并把自己注册为 `debug` 服务。
- **_process()**：每帧刷新调试文本。
- **toggle()**：调试快捷键切换显示。
- **_build_text()**：拼装状态路径、最近命令、HP 和最近事件。

---

### 27.101 DebugOverlay 使用示例

#### 详细实际用例

- 真实场景：Phase 0/1 验证时，按下攻击键后 DebugOverlay 实时显示 `State: Player/Alive/Combat/BasicAttack`、`Last command: attack`、`HP: 80 / 100` 和最近的 `damage_applied`、`entity_died`。
- 怎么使用：GameBootstrap（或 Main 场景）实例化 DebugOverlay，设置 watch_entity_path 指向玩家；不要做成 autoload，避免与 class_name 冲突。
- 验证重点：关闭 DebugOverlay 不影响任何 gameplay；它只读取状态，不修改。

```gdscript
var overlay := DebugOverlay.new()
overlay.watch_entity_path = player.get_path()
add_child(overlay)
```

---

