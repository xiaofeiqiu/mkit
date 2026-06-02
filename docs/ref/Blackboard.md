# Blackboard

## 概念说明

Blackboard 是行为系统的短期共享记忆。负责保存移动方向、当前目标、临时计时器、AI 决策值、状态间共享数据等运行时临时数据。State、Action、AI 经常需要共享少量运行时数据，但不应该互相直接持有大量引用。

## 设计目的

给 AI、HFSM、Action 提供轻量的临时数据共享机制。Blackboard 存储短期行为数据，不替代正式状态对象，也不存储永久角色属性。每个 StateMachine 持有一个 Blackboard 实例，下属所有 State 共享访问。

## 文件

`res://addons/mkit/kernel/context/blackboard.gd`

## 接口

```gdscript
class_name Blackboard
extends RefCounted

var _data: Dictionary = {}

func set_value(key: String, value) -> void

func get_value(key: String, default_value = null)

func has_value(key: String) -> bool

func erase_value(key: String) -> void

func clear() -> void

func to_debug_dict() -> Dictionary
```

## 函数使用场景

- **set_value()**：写入短期数据。例：MoveState 处理 move 命令后把移动方向存入 Blackboard 的 `move_direction`，physics_update 帧再读取。
- **get_value()**：读取短期数据。例：AttackState 读取 `last_facing_direction` 来决定挥剑方向。
- **has_value()**：检查数据是否存在。例：AI 检查 Blackboard 中是否已有目标，避免每帧都重新扫描。
- **erase_value()**：删除特定键。例：状态退出时清理不再需要的临时目标引用。
- **clear()**：清空所有数据。例：实体死亡或重置时清空 Blackboard，避免旧数据污染新状态。
- **to_debug_dict()**：调试输出。例：DebugOverlay 显示当前 Blackboard 中所有键值对。

## 使用示例

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
