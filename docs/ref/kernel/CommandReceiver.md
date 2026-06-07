# CommandReceiver

**层：** Kernel  
**文件：** `addons/mkit/kernel/commands/command_receiver.gd`  
**继承：** `extends Node`

## 职责

实体接收命令的入口节点。`_ready` 时按 `receiver_id`（默认取自同实体 `EntityIdentity.entity_id`）向 `CommandService` 注册自己；若注册时服务尚未就绪，会在后续帧重试。收到命令后转交给同实体的 `StateMachine.handle_command`，未处理则走 `handle_unhandled_command` 兜底。退出场景树时会从 `CommandService` 注销，避免释放后的实体继续接收命令。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `receiver_id` | `String`（@export）| `""` | 注册键；空则从 `EntityIdentity.entity_id` 填充 |
| `auto_register` | `bool`（@export）| `true` | `_ready` 时是否自动注册到 `CommandService` |
| `owner_entity` | `Node` | — | 所属实体（`owner` 或父节点）|
| `state_machine` | `StateMachine` | — | 同实体的 `StateMachine`（自动定位）|
| `command_history` | `Array[GameCommand]` | `[]` | 最近命令（上限 `max_history=20`，调试用）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `configure_receiver_id(id: String) -> void` | — | 设置 id；若已注册则先注销旧 id，再用新 id 重新注册（`EntitySpawner` 用）|
| `receive_command(command: GameCommand) -> bool` | `bool` | 记录历史 → 交给 StateMachine → 兜底，返回是否处理 |
| `handle_unhandled_command(command) -> bool` | `bool` | 兜底钩子，**子类可 override** 处理 StateMachine 不响应的命令 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 多数情况无需写代码：在实体场景里挂 CommandReceiver 节点即可
# receiver_id 留空 → 自动用 EntityIdentity.entity_id
```

### 典型场景（Level 2）

```gdscript
# 兜底处理 StateMachine 不关心的命令（如打开背包）
class_name PlayerCommandReceiver
extends CommandReceiver


func handle_unhandled_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.OPEN_INVENTORY:
            var ui := ServiceRegistry.get_port(ServiceRegistry.SERVICE_UI) as UIManager
            if ui != null:
                ui.open_screen("inventory", {}, true)
                return true
    return false
```

## 相关

- → [CommandService](CommandService.md)（路由到此）· [GameCommand](GameCommand.md)
- → [StateMachine](StateMachine.md)（命令的主处理者）
- → [pipeline.md — Command Dispatch](../../pipeline.md#3-command-dispatch)
