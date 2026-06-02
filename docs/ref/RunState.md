# RunState

## 概念说明

RunState 是一局 roguelike run 的运行时存档对象。它保存 run_id、seed、当前层、当前房间、临时升级、run currency、房间历史和奖励历史。RunDirector 推进流程、存档恢复和 Debug 复现都需要一个权威 Run 状态。

## 设计目的

把一局 Run 的全部运行时状态集中到一个可序列化的对象，使 RunDirector 能修改它、SaveManager 能保存它、Debug 工具能读取它，同时固定 seed 保证同一局可以复现。

## 文件

`res://addons/mkit/modules/run/run_state.gd`

## 接口

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

static func create(seed_value: int) -> RunState: ...
func to_save_data() -> Dictionary: ...
```

## 函数使用场景

- **`create(seed_value)`**：工厂方法，生成唯一 run_id（基于微秒时间戳），绑定 seed。RunDirector.start_run() 调用此方法创建新局运行时状态。
- **`to_save_data()`**：将 RunState 序列化为 Dictionary，供 SaveManager 在局中断点存档时保存；支持"中途退出续玩"功能。

RunState 的字段在 run 过程中由 RunDirector 修改：
- **`status`**：`"not_started" → "starting" → "active" → "choosing_reward" → "completed" / "failed"`。
- **`room_history`**：每次进入新房间时追加 room_definition_id。
- **`reward_history`**：玩家选择奖励后追加 reward_id。
- **`current_room_index`**：RunDirector.select_reward() 执行成功后 +1，推进到下一房间。

## 使用示例

```gdscript
var run := RunState.create(12345)
run.current_floor = 1
run.current_room_id = "room.dungeon_small_01"
run.temporary_upgrade_ids.append("reward.attack_plus_20")

var save_data := run.to_save_data()
print("Run ID: ", run.run_id)
print("Status: ", run.status)
```
