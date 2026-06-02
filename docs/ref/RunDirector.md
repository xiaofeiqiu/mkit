# RunDirector

## 概念说明

RunDirector 是一局 Roguelike Run 的导演。它负责开始 Run、进入房间、处理奖励、推进楼层、死亡失败或胜利完成。没有 RunDirector，房间、奖励、死亡和进度逻辑会分散到很多场景脚本。

## 设计目的

作为 Run 生命周期的单一协调者，把"开始 Run → 进入房间 → 清房间 → 选奖励 → 进入下一房间 → 完成/失败"的全部阶段转换集中管理，不负责伤害计算、UI 绘制或背包操作，只协调各系统之间的阶段推进。

## 文件

`res://addons/mkit/modules/room/run_director.gd`

## 字段说明

- **first_floor_room_pool**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **room_scene_container_path**：资源或节点路径。例：用 room_scene_container_path 指向场景或节点，方便在 Inspector 中配置。
- **player_group**：玩家节点 group。例：选择奖励时用它找到奖励效果的 source/target。
- **player_entity_id**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **run_length**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **run_state**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **room_graph**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **current_room_controller**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name RunDirector
extends Node
signal run_started(run_state: RunState)
signal room_enter_requested(room_id: String)
signal choosing_reward(options: Array[RewardOption])
signal run_finished(result: String)
@export var first_floor_room_pool: Array[String] = []
@export var room_scene_container_path: NodePath = NodePath("../RoomRoot")
@export var player_group: String = "player"
@export var player_entity_id: String = "player_001"
@export var run_length: int = 3
var run_state: RunState = null
var room_graph: RoomGraph = null
var current_room_controller: RoomController = null
func start_run(seed: int = 0) -> void
func enter_next_room() -> void
func on_room_cleared(room_controller: RoomController) -> void
func select_reward(option: RewardOption) -> void
func complete_run() -> void
func fail_run(reason: String) -> void
```

## 函数使用场景

- **`start_run(seed)`**：创建 RunState、设置 RandomService seed、调用 DungeonGenerator 生成 RoomGraph，发出 `run_started` 事件，然后调用 `enter_next_room()`。seed=0 时自动生成随机 seed。
- **`enter_next_room()`**：按 `run_state.current_room_index` 从 RoomGraph 取当前 RoomNode，若超出范围则调用 `complete_run()`；否则加载房间场景、setup RoomController 并调用 enter_room()，监听 room_cleared 信号。
- **`on_room_cleared(room_controller)`**：房间清理信号处理，将 run_state.status 设为 `"choosing_reward"`，发出 `choosing_reward` 信号携带 reward_options，让 UI 打开奖励选择界面。
- **`select_reward(option)`**：玩家选择奖励后由 UI 调用。通过 RewardSystem.apply_selected() 执行效果，记录 reward_history，`current_room_index += 1`，再次调用 `enter_next_room()`。
- **`complete_run()`**：房间图遍历结束时调用，设置 status="completed"，发出 `run_finished("completed")` 信号和 EventRouter 事件。
- **`fail_run(reason)`**：玩家死亡或致命错误时调用，设置 status="failed"，发出 `run_finished("failed:...")` 信号。

## 使用示例

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

func _on_choosing_reward(options: Array[RewardOption]) -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("reward_selection", {
        "options": options,
        "run_director": $RunDirector
    }, true)
```
