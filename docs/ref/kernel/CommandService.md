# CommandService

**层：** Kernel  
**文件：** `addons/mkit/kernel/commands/command_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"commands"`

## 职责

命令路由器。维护 `receiver_id → CommandReceiver` 映射，将 `GameCommand` 分发到目标实体的 `CommandReceiver`。

## 字段（public var）

无公开字段（内部 `_receivers: Dictionary`）。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_receiver(id: String, receiver: CommandReceiver) -> void` | `void` | 注册接收器；`CommandReceiver.auto_register = true` 时自动调用 |
| `unregister_receiver(id: String) -> void` | `void` | 实体销毁时调用（`CommandReceiver._exit_tree` 内）|
| `dispatch(command: GameCommand) -> bool` | `bool` | 路由到 `command.target_id` 对应的接收器；返回是否被处理 |
| `broadcast(command: GameCommand, receiver_ids: Array[String]) -> int` | `int` | 向多个接收器广播（克隆命令）；返回成功处理数 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `command_dispatched` | `command: GameCommand` | 每次 dispatch 时（无论是否成功）|
| `command_failed` | `command: GameCommand, reason: String` | target_id 为空、无接收器、接收器无效时 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var cmds := ServiceRegistry.get_service("commands") as CommandService
var cmd := GameCommand.create(BuiltinCommands.ATTACK, "player", "enemy_1")
var handled := cmds.dispatch(cmd)
```

### 典型场景（Level 2）

```gdscript
func _on_input_attack() -> void:
    var cmds := ServiceRegistry.get_service("commands") as CommandService
    if cmds == null:
        return

    var cmd := GameCommand.create(BuiltinCommands.ATTACK, "player", "player")
    var handled := cmds.dispatch(cmd)

    if not handled:
        # 可能是当前状态不接受攻击命令（如在 Dead 状态）
        push_warning("Attack command ignored by player")


func _broadcast_area_command(command_type: String, ids: Array[String]) -> void:
    var cmds := ServiceRegistry.get_service("commands") as CommandService
    if cmds == null:
        return
    var cmd := GameCommand.create(command_type, "game_master", "", {})
    var count := cmds.broadcast(cmd, ids)
    print("Broadcast handled by %d receivers" % count)


func _on_command_failed(command: GameCommand, reason: String) -> void:
    push_warning("Command '%s' → '%s' failed: %s" % [
        command.command_type, command.target_id, reason
    ])
```

## 相关

- → [GameCommand](GameCommand.md) — 命令对象结构
- → [CommandReceiver](CommandReceiver.md) — 接收端实现
- → [BuiltinCommands](BuiltinCommands.md) — 内置命令类型
- → [pipeline.md — Command Dispatch](../pipeline.md#3-command-dispatch)
- → [cookbook/02_player_entity.md](../cookbook/02_player_entity.md)
