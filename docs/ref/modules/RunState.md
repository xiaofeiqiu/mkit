# RunState

**层：** Module  
**文件：** `addons/mkit/modules/world/dungeon/run_state.gd`  
**继承：** `extends RefCounted`

## 职责

一局 run 的运行状态。记录 seed、当前房间、房间历史、奖励历史和状态字符串。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `run_id` | `String` | `""` | `create()` 生成的运行时 ID |
| `seed` | `int` | `0` | 随机种子 |
| `current_floor` | `int` | `1` | 当前楼层 |
| `current_room_index` | `int` | `0` | 当前房间序号 |
| `current_room_id` | `String` | `""` | 当前房间定义 ID |
| `elapsed_time` | `float` | `0.0` | 运行时间 |
| `temporary_upgrade_ids` | `Array[String]` | `[]` | 局内升级 |
| `run_currency` | `Dictionary` | `{}` | 局内货币 |
| `enemy_scaling_level` | `int` | `1` | 敌人缩放等级 |
| `room_history` | `Array[String]` | `[]` | 已进入房间 |
| `reward_history` | `Array[String]` | `[]` | 已选奖励 |
| `rng_state` | `Dictionary` | `{}` | 随机状态扩展位 |
| `status` | `String` | `"not_started"` | `starting` / `active` / `choosing_reward` / `completed` / `failed` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(seed_value: int) -> RunState` | `RunState` | 创建 run，写 seed 和 `run_<ticks>` |
| `to_save_data() -> Dictionary` | `Dictionary` | 序列化当前状态 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var state: RunState = RunState.create(123)
state.status = "active"
```

### 典型场景（Level 2）

```gdscript
func describe_run(state: RunState) -> String:
    if state == null:
        return "no run"
    return "%s room %d status %s" % [state.run_id, state.current_room_index, state.status]
```

## 相关

- → [RunDirector](RunDirector.md) · [RoomGraph](RoomGraph.md)

