# RoomController

## 概念说明

RoomController 是房间生命周期控制器。它负责生成敌人、追踪存活敌人、判断清房间、生成奖励并通知 RunDirector。房间是战斗、奖励和 Run 推进的交汇点，需要明确控制者。

## 设计目的

把房间从进入到清理的全部逻辑（刷怪、追踪敌人死亡、生成奖励）集中到一个节点，使 RunDirector 只需调用 `enter_room()` 并监听信号，不需要了解房间内部的具体实现。

## 文件

`res://addons/mkit/modules/room/room_controller.gd`

## 接口

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
var active_enemies: Dictionary = {}
var content: ContentRegistry = null
var entity_spawner: EntitySpawner = null

func setup(definition_id: String) -> void: ...
func enter_room() -> void: ...
func spawn_enemies() -> void: ...
func check_clear_condition() -> void: ...
func generate_reward() -> void: ...
func get_definition() -> RoomDefinition: ...
```

## 函数使用场景

- **`setup(definition_id)`**：初始化 room_definition_id 并创建 RoomRuntime。RunDirector._load_room() 在实例化房间场景后立即调用此方法。
- **`enter_room()`**：开始房间流程：标记 runtime.entered=true，调用 spawn_enemies()，发出 `room_entered` 信号。RunDirector 在房间场景加载后调用。
- **`spawn_enemies()`**：读取 RoomDefinition.enemy_spawn_ids，通过 EntitySpawner 逐一生成敌人，记录 entity_id 到 active_enemies 和 runtime.active_enemy_ids。
- **`check_clear_condition()`**：每次敌人死亡后（由 `_on_entity_died` 触发），检查 active_enemies 是否清空；清空则先调用 generate_reward()，再发出 `room_cleared` 和 EventRouter `room_cleared` 事件。注意奖励先于信号发出，确保 RunDirector 收到信号时 reward_options 已就绪。
- **`generate_reward()`**：调用 RewardSystem.generate_options()，把结果写入 runtime.reward_options，并发出 `reward_ready` 信号。
- **`get_definition()`**：从 ContentRegistry 读取当前房间的 RoomDefinition，内部各方法调用。

## 使用示例

### 进入房间

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
