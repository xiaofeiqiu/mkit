# GameCommand

**层：** Kernel  
**文件：** `addons/mkit/kernel/commands/game_command.gd`  
**继承：** `extends RefCounted`

## 职责

将一个游戏意图封装为类型化对象，传递给 `CommandService` 路由到目标实体。Command 是意图的载体，不直接执行任何逻辑。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `command_id` | `String` | `""` | 自动生成的唯一 ID（`type_ticks`）|
| `command_type` | `String` | `""` | 命令类型，如 `BuiltinCommands.MOVE`、`"attack"` |
| `source_id` | `String` | `""` | 发出命令的实体 ID |
| `target_id` | `String` | `""` | 接收命令的实体 ID（对应 `CommandReceiver.receiver_id`）|
| `timestamp` | `float` | `0.0` | 创建时的游戏时间（秒）|
| `priority` | `int` | `0` | 预留，用于多命令排序 |
| `payload` | `Dictionary` | `{}` | 命令附带数据（方向、技能 ID、物品 ID 等）|
| `consumed` | `bool` | `false` | 被处理后调 `mark_consumed()` 标记 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static create(type, source, target, data) -> GameCommand` | `GameCommand` | 工厂方法，自动填充 `command_id` 和 `timestamp` |
| `mark_consumed() -> void` | `void` | 标记命令已被处理（由 CommandReceiver 调用）|
| `get_vector2(key, default) -> Vector2` | `Vector2` | 从 payload 安全读取 Vector2 |
| `get_string(key, default) -> String` | `String` | 从 payload 安全读取 String |
| `get_float(key, default) -> float` | `float` | 从 payload 安全读取 float |

## 使用模式

### 最小示例（Level 1）

```gdscript
var cmd := GameCommand.create(BuiltinCommands.MOVE, "player", "player", {
    "direction": Vector2.RIGHT
})
```

### 典型场景（Level 2）

```gdscript
func _send_attack_command(source_id: String, target_id: String) -> void:
    var commands := ServiceRegistry.get_service("commands") as CommandService
    if commands == null:
        push_error("CommandService not available")
        return

    var cmd := GameCommand.create(
        BuiltinCommands.ATTACK,
        source_id,
        target_id,
        {}
    )
    var handled := commands.dispatch(cmd)
    if not handled:
        # 目标不存在或状态未响应
        push_warning("Attack command not handled (target=%s)" % target_id)


func _send_ability_command(caster_id: String, ability_id: String) -> void:
    var commands := ServiceRegistry.get_service("commands") as CommandService
    if commands == null:
        return
    var cmd := GameCommand.create(
        BuiltinCommands.CAST_ABILITY,
        caster_id,
        caster_id,
        {"ability_id": ability_id}
    )
    commands.dispatch(cmd)
```

## 相关

- → [CommandService](CommandService.md) — dispatch / broadcast
- → [CommandReceiver](CommandReceiver.md) — receive_command
- → [BuiltinCommands](BuiltinCommands.md) — 内置命令类型常量
- → [GameplayContext](GameplayContext.md) — `from_command(cmd, source, target)` 从命令创建上下文
- → [pipeline.md — Command Dispatch](../../pipeline.md#3-command-dispatch)
