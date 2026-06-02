# CommandReceiver

## 概念说明

CommandReceiver 是挂在实体上的命令接收端组件。负责将来自 CommandRouter 的命令转交给所属实体的 StateMachine，记录命令历史，并在 StateMachine 无法处理时提供 fallback 扩展点。没有命令路由时，Input 和 AI 往往直接调用具体节点方法，系统会快速变成强耦合。

## 设计目的

作为实体与命令系统之间的桥梁，使命令发送者（InputReader、AI Brain）不需要知道接收者内部结构。每个需要接收命令的实体都注册一个 receiver_id，CommandRouter 据此投递命令。

## 文件

`res://addons/mkit/kernel/commands/command_receiver.gd`

## 字段说明

- **receiver_id**：命令接收者 ID。例：player_001 的 CommandReceiver 注册后，CommandRouter 才能把攻击命令投递给玩家。
- **auto_register**：是否自动注册到路由器。例：敌人生成后自动注册 receiver，就能立刻接收 AI 命令。
- **owner_entity**：拥有该组件或状态机的实体。例：PlayerMoveState 需要通过 owner_entity 读取 StatsComponent 并推动 CharacterBody2D。
- **state_machine**：所属状态机引用。例：AttackState 完成后通过 state_machine 请求回到 Idle。
- **command_history**：最近命令历史。例：玩家卡住时可以看到最后收到的是 dash 还是 attack。
- **max_history**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

## 接口

```gdscript
class_name CommandReceiver
extends Node
@export var receiver_id: String = ""
@export var auto_register: bool = true
var owner_entity: Node = null
var state_machine: StateMachine = null
var command_history: Array[GameCommand] = []
var max_history: int = 20
func receive_command(command: GameCommand) -> bool
func handle_unhandled_command(command: GameCommand) -> bool
```

## 函数使用场景

- **receive_command()**：命令投递入口。例：CommandRouter 找到玩家的 receiver 后调用此方法，先记录历史，再让 StateMachine 处理，处理不了则调用 `handle_unhandled_command`。
- **handle_unhandled_command()**：未处理命令的 fallback 扩展点。例：子类可覆盖此方法，处理 StateMachine 不负责的命令，如打开背包 UI。

## 使用示例

### Player 场景结构

```text
Player.tscn
  CharacterBody2D
    EntityIdentity
    CommandReceiver
    StateMachine
    Components
    Controllers
```

### 配置 CommandReceiver

```gdscript
func _ready() -> void:
    $CommandReceiver.receiver_id = $EntityIdentity.entity_id
```

### 自定义 fallback command 处理

```gdscript
class_name PlayerCommandReceiver
extends CommandReceiver

func handle_unhandled_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.OPEN_INVENTORY:
        var ui := ServiceRegistry.get_service("ui") as UIManager
        ui.open_screen("inventory")
        return true
    return false
```
