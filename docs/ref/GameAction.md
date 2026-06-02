# GameAction

## 概念说明

GameAction 是一个随时间推进的玩法过程。负责表达攻击前摇/生效/后摇、Dash 持续时间、施法时间、延迟生成、等待动画等过程。State 表示当前模式，Action 表示正在执行的时间过程，分开后行为更容易取消、调试和复用。

## 设计目的

将时间性游戏过程封装为可复用的对象，通过信号通知状态机动作完成或取消。Action 只接收 ActionContext，不直接依赖具体实体脚本，因此可以在玩家和敌人之间复用。

## 文件

`res://addons/mkit/kernel/actions/game_action.gd`

## 字段说明

- **action_id**：稳定 ID 字段。例：GameAction 通过 action_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **context**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **elapsed**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **finished**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **cancelled_flag**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **cancel_tags**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name GameAction
extends RefCounted
signal completed(action: GameAction)
signal cancelled(action: GameAction, reason: String)
var action_id: String = ""
var context: ActionContext = null
var elapsed: float = 0.0
var finished: bool = false
var cancelled_flag: bool = false
var cancel_tags: Array[String] = []
func start(ctx: ActionContext) -> void
func update(delta: float) -> void
func cancel(reason: String = "") -> void
func complete() -> void
func is_finished() -> bool
func can_cancel_with(tag: String) -> bool
```

## 函数使用场景

- **start()**：启动 Action，由 ActionRunner 调用。例：BasicAttackState 创建 TimedAttackAction 后将其交给 ActionRunner.start_action。
- **update()**：每帧推进 Action 时间，由 ActionRunner 调用。
- **cancel()**：强制取消 Action。例：玩家被眩晕时调用 ActionRunner.cancel_actions_for_source，后者调用每个 Action 的 cancel。
- **complete()**：标记 Action 完成并发出信号。例：TimedAttackAction 在 recovery 结束时调用，通知状态机回到 Idle。
- **is_finished()**：查询 Action 是否已结束（完成或取消）。例：ActionRunner 每帧检查后清理已完成的 Action。
- **can_cancel_with()**：检查是否可以被特定标签取消。例：attack recovery 阶段标记可被 dash 取消，MoveState 在命中 dash 命令时检查此条件。

## 使用示例

### 自定义 Action（等待指定时间）

```gdscript
class_name WaitThenPrintAction
extends GameAction

var duration: float = 1.0

func _on_start() -> void:
    print("Wait action started")

func _on_update(delta: float) -> void:
    if elapsed >= duration:
        complete()

func _on_complete() -> void:
    print("Wait action completed")
```

### 启动 Action

```gdscript
var action := WaitThenPrintAction.new()
var ctx := ActionContext.new()
ctx.source = player
ServiceRegistry.get_service("actions").start_action(action, ctx)
```
