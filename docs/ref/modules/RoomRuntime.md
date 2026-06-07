# RoomRuntime

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/room_runtime.gd`  
**继承：** `extends RefCounted`

## 职责

房间运行时状态。`RoomController` 记录是否进入、是否清空、活跃敌人和已生成奖励选项。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `room_runtime_id` | `String` | `""` | 运行时唯一 ID，`create()` 用时间生成 |
| `definition_id` | `String` | `""` | `RoomDefinition.room_id` |
| `cleared` | `bool` | `false` | 是否清空 |
| `entered` | `bool` | `false` | 是否进入 |
| `active_enemy_ids` | `Array[String]` | `[]` | 当前活跃敌人 ID |
| `reward_options` | `Array[RewardOption]` | `[]` | 本房间生成的奖励 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(definition_id: String) -> RoomRuntime` | `RoomRuntime` | 创建 runtime，写入 definition_id 和 `room_<ticks>` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var runtime: RoomRuntime = RoomRuntime.create("room.combat_a")
runtime.entered = true
```

### 典型场景（Level 2）

```gdscript
func is_room_done(controller: RoomController) -> bool:
    return controller.runtime != null and controller.runtime.cleared
```

## 相关

- → [RoomController](RoomController.md) · [RewardOption](RewardOption.md)

