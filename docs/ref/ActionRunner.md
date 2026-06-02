# ActionRunner

## 概念说明

ActionRunner 是所有活动 Action 的更新器。负责启动、更新、取消、完成并清理 Action，同时提供信号和调试信息。如果每个状态自己写 timer 和 update，后续取消、暂停、调试都会变得分散。

## 设计目的

集中管理所有正在运行的 Action，确保暂停时 Action 不推进（通过 TimeService 获取缩放 delta），多个 Action 并发时互不干扰，取消一个不影响其他。

## 文件

`res://addons/mkit/kernel/actions/action_runner.gd`

## 接口

```gdscript
class_name ActionRunner
extends Node

signal action_started(action: GameAction)
signal action_completed(action: GameAction)
signal action_cancelled(action: GameAction, reason: String)

var active_actions: Array[GameAction] = []

func start_action(action: GameAction, context: ActionContext) -> GameAction

func cancel_actions_for_source(source: Node, reason: String = "") -> void
```

## 函数使用场景

- **start_action()**：注册并启动 Action。例：BasicAttackState 进入时调用此方法启动 TimedAttackAction，runner 开始每帧推进它。
- **cancel_actions_for_source()**：取消某个实体的所有 Action。例：玩家被眩晕时调用此方法，传入 player 节点，停止所有正在进行的动作。

## 使用示例

### 启动 Dash Action

```gdscript
func start_dash(player: Node, direction: Vector2) -> void:
    var action := DashAction.new()
    var ctx := ActionContext.new()
    ctx.source = player
    ctx.direction = direction

    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(action, ctx)
```

### 眩晕实体时取消所有 Action

```gdscript
func stun_entity(entity: Node) -> void:
    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.cancel_actions_for_source(entity, "stunned")
```
