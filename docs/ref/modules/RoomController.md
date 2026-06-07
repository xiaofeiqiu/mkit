# RoomController

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_controller.gd`  
**继承：** `extends Node`

## 职责

房间运行控制器。进入时按 `RoomDefinition.enemy_spawn_ids` spawn 敌人，监听 `entity_died`，清空后生成奖励并广播 `room_cleared`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `room_definition_id` | `String`（@export）| `""` | 当前房间定义 ID；`RoomLoader` 会自动 setup |
| `enemy_container_path` | `NodePath`（@export）| `"../Enemies"` | 敌人父节点 |
| `entity_spawner_path` | `NodePath`（@export）| `"../EntitySpawner"` | `EntitySpawner` 路径 |
| `reward_count` | `int`（@export）| `3` | 生成奖励选项数量 |
| `spawn_positions` | `Array[Vector2]`（@export）| `[]` | 敌人出生点 |
| `runtime` | `RoomRuntime` | `null` | 当前房间状态 |
| `active_enemies` | `Dictionary` | `{}` | entity_id → enemy node |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `setup(definition_id: String) -> void` | — | 写 `room_definition_id` 并创建 `RoomRuntime` |
| `enter_room() -> void` | — | 标记进入、spawn 敌人、发 `room_entered` |
| `spawn_enemies() -> void` | — | 按 room definition 的 `enemy_spawn_ids` 实例化 |
| `check_clear_condition() -> void` | — | 无活跃敌人时标记 cleared、生成奖励、发事件 |
| `generate_reward() -> void` | — | 调 `"loot"` 服务生成 `RewardOption` |
| `get_definition() -> RoomDefinition` | `RoomDefinition` | 从 `ContentService` 查询 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `room_entered` | `room_id` | `enter_room()` 后 |
| `room_cleared` | `room_id` | 活跃敌人清空后 |
| `reward_ready` | `options` | 奖励生成完成 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var controller: RoomController = $RoomController
controller.setup("room.combat_a")
controller.enter_room()
```

### 典型场景（Level 2）

```gdscript
func bind_room(controller: RoomController) -> void:
    controller.reward_ready.connect(func(options: Array[RewardOption]) -> void:
        if options.is_empty():
            return
        _show_reward_options(options)
    )
    controller.room_cleared.connect(func(room_id: String) -> void:
        print("Room cleared: %s" % room_id)
    )
```

## 相关

- → [RoomDefinition](RoomDefinition.md) · [RoomRuntime](RoomRuntime.md) · [EntitySpawner](EntitySpawner.md) · [LootService](LootService.md)
- → [cookbook/07_room.md](../../cookbook/07_room.md) · [pipeline.md — Room / Run](../../pipeline.md#18-room--run)

