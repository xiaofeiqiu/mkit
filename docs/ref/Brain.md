# Brain

## 概念说明

Brain 是 AI 决策组件的基类。它观察局势并发出命令，而不是直接修改 gameplay 系统。AI 和玩家走同一条命令链路，敌人行为才容易测试和替换。

## 设计目的

提供所有 AI 脑的统一基类，确保 AI 只通过 `issue_command()` 发出 GameCommand，而不直接调用战斗系统或状态机，使 AI 行为可以用相同的命令验证框架测试，也可以在不改变上层架构的情况下替换不同的 AI 实现。

## 文件

`res://addons/mkit/modules/ai/brain.gd`

## 接口

```gdscript
class_name Brain
extends Node

@export var enabled: bool = true
@export var think_interval: float = 0.2

var _timer: float = 0.0
var command_router: CommandRouter = null
var target: Node = null

func _ready() -> void: ...
func _process(delta: float) -> void: ...
func think() -> void: ...
func issue_command(command_type: String, payload: Dictionary = {}) -> bool: ...
func _get_owner_id() -> String: ...
```

## 函数使用场景

- **`think()`**：AI 决策入口，每 `think_interval` 秒由 `_process` 调用一次。子类重写此方法实现具体 AI 逻辑（追击、攻击、施法、巡逻）。`enabled=false` 时跳过。
- **`issue_command(command_type, payload)`**：封装创建 GameCommand 和调用 CommandRouter.dispatch() 的操作，source_id 和 target_id 均设为 owner 的 entity_id，使 AI 命令经过 CommandReceiver 和 StateMachine 的标准处理链路。

## 使用示例

### 自定义 BossBrain

```gdscript
class_name BossBrain
extends Brain

func think() -> void:
    if target == null:
        target = get_tree().get_first_node_in_group("player")
        return

    var hp := owner.get_node("Components/HealthComponent") as HealthComponent
    var hp_percent := hp.current_hp / hp.get_max_hp()

    if hp_percent < 0.5:
        issue_command(BuiltinCommands.CAST_ABILITY, {"ability_id": "ability.boss_rage"})
    else:
        issue_command(BuiltinCommands.ATTACK, {"target": target})
```
