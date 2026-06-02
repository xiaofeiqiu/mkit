# RoomRuntime

## 概念说明

RoomRuntime 是一间房在本局 Run 中的运行时状态。它记录是否进入、是否清理、活跃敌人 ID 列表、已生成奖励选项和临时房间数据。同一个 RoomDefinition 可以在不同 Run 里出现，每次的敌人、清理状态和奖励状态都不一样。

## 设计目的

区分静态房间配置（RoomDefinition）和本局运行时状态（RoomRuntime），使同一房间定义在每局 Run 中都拥有独立的运行时状态，支持存档恢复和多房间并发（分支地图）时状态互不污染。

## 文件

`res://addons/mkit/modules/room/room_runtime.gd`

## 字段说明

- **room_runtime_id**：稳定 ID 字段。例：RoomRuntime 通过 room_runtime_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **cleared**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **entered**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **active_enemy_ids**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **reward_options**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

## 接口

```gdscript
class_name RoomRuntime
extends RefCounted
var room_runtime_id: String = ""
var definition_id: String = ""
var cleared: bool = false
var entered: bool = false
var active_enemy_ids: Array[String] = []
var reward_options: Array[RewardOption] = []
static func create(definition_id: String) -> RoomRuntime
```

## 函数使用场景

- **`create(definition_id)`**：工厂方法，生成唯一 room_runtime_id（基于微秒时间戳），绑定 definition_id。RoomController.setup() 调用此方法创建本局运行时状态。

字段在运行时由 RoomController 写入：

- **`entered`**：RoomController.enter_room() 设为 true，标记房间已被进入。
- **`active_enemy_ids`**：RoomController.spawn_enemies() 填充，每个敌人死亡时移除对应 ID；全部移除后触发清房间判断。
- **`cleared`**：RoomController.check_clear_condition() 设为 true，防止重复触发清房间事件。
- **`reward_options`**：RoomController.generate_reward() 填充，RunDirector.on_room_cleared() 读取并传给 UI。

## 使用示例

```gdscript
var runtime := RoomRuntime.create("room.dungeon_small_01")
runtime.entered = true
runtime.active_enemy_ids = ["goblin_001", "slime_001"]

# 敌人死亡后
runtime.active_enemy_ids.erase("goblin_001")
if runtime.active_enemy_ids.is_empty():
    runtime.cleared = true
```
