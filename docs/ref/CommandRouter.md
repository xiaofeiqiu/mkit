# CommandRouter

## 概念说明

CommandRouter 是命令生产者和消费者之间的路由层。负责根据 target_id 找到对应的 CommandReceiver 并投递命令，记录历史，并通过信号暴露派发成功或失败状态。没有命令路由时，Input 和 AI 往往直接调用具体节点方法，系统会快速变成强耦合。

## 设计目的

统一命令分发入口，使任何来源（玩家输入、AI、测试脚本）的命令都通过同一路径到达目标实体。支持单目标派发和多目标广播，失败时通过信号暴露原因。

## 文件

`res://addons/mkit/kernel/commands/command_router.gd`

## 接口

```gdscript
class_name CommandRouter
extends Node

signal command_dispatched(command: GameCommand)
signal command_failed(command: GameCommand, reason: String)

var _receivers: Dictionary = {}

func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void

func unregister_receiver(receiver_id: String) -> void

func dispatch(command: GameCommand) -> bool

func broadcast(command: GameCommand, receiver_ids: Array[String]) -> int
```

## 函数使用场景

- **register_receiver()**：注册接收者。例：CommandReceiver 在 `_ready()` 中调用此方法，把自己和 entity_id 注册到路由器。
- **unregister_receiver()**：注销接收者。例：敌人死亡或场景卸载时调用，避免命令发到无效节点。
- **dispatch()**：单目标命令派发。例：PlayerInputReader 把 attack 命令 dispatch 给 player_001，路由器找到对应 receiver 后投递。
- **broadcast()**：多目标命令广播。例：向多个敌人同时发出 stop_move 命令；每个目标会收到一个命令副本。

## 使用示例

### 注册 Receiver

```gdscript
func _ready() -> void:
    var router := ServiceRegistry.get_service("commands") as CommandRouter
    router.register_receiver("player_001", $Player/CommandReceiver)
```

### 派发攻击命令

```gdscript
var attack_cmd := GameCommand.create(
    BuiltinCommands.ATTACK,
    "player_001",
    "player_001",
    {"direction": Vector2.RIGHT}
)

var handled := router.dispatch(attack_cmd)
if not handled:
    print("Attack command was not handled")
```
