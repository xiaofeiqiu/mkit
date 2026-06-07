# RunDirector

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/run_director.gd`  
**继承：** `extends Node`

## 职责

Run 编排器。生成房间图、加载房间、在房间清空后处理奖励选择和推进，并在玩家死亡或房间序列完成时结束 run。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `first_floor_room_pool` | `Array[String]`（@export）| `[]` | 线性图抽取的 room id 池 |
| `room_scene_container_path` | `NodePath`（@export）| `"../RoomRoot"` | 当前房间场景容器 |
| `player_group` | `String`（@export）| `"player"` | 奖励应用目标 group |
| `player_entity_id` | `String`（@export）| `"player_001"` | 判断玩家死亡的 entity id |
| `run_length` | `int`（@export）| `3` | 房间数量 |
| `run_state` | `RunState` | `null` | 当前 run 状态 |
| `room_graph` | `RoomGraph` | `null` | 当前房间图 |
| `current_room_controller` | `RoomController` | `null` | 当前房间控制器 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `start_run(seed: int = 0) -> void` | — | 校验房间池，创建 `RunState`，生成图并进入首房间 |
| `enter_next_room() -> void` | — | 按 `current_room_index` 加载下一房间；越界则完成 |
| `on_room_cleared(room_controller: RoomController) -> void` | — | 有奖励则进入选择状态，否则推进 |
| `select_reward(option: RewardOption) -> void` | — | 应用奖励，记录历史，进入下一房间 |
| `complete_run() -> void` | — | 标记 completed、清理图、发事件 |
| `fail_run(reason: String) -> void` | — | 标记 failed、清理图、发事件 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `run_started` | `run_state` | `start_run()` 成功 |
| `room_enter_requested` | `room_id` | 准备加载房间 |
| `choosing_reward` | `options` | 房间清空且有奖励 |
| `run_finished` | `result` | 完成或失败 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var director: RunDirector = $RunDirector
director.first_floor_room_pool = ["room.combat_a"]
director.start_run(42)
```

### 典型场景（Level 2）

```gdscript
func boot_run(director: RunDirector) -> void:
    director.choosing_reward.connect(func(options: Array[RewardOption]) -> void:
        if not options.is_empty():
            director.select_reward(options[0])
    )
    director.run_finished.connect(func(result: String) -> void:
        print("Run finished: %s" % result)
    )
    if director.first_floor_room_pool.is_empty():
        return
    director.start_run(0)
```

## 相关

- → [RunState](RunState.md) · [DungeonGenerator](DungeonGenerator.md) · [RoomLoader](RoomLoader.md) · [RewardCoordinator](RewardCoordinator.md)
- → [cookbook/07_room.md](../../cookbook/07_room.md) · [pipeline.md — Room / Run](../../pipeline.md#18-room--run)

