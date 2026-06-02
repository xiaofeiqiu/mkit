# DashAction

## 概念说明

DashAction 是短时间位移爆发 Action。按方向和速度推动实体一小段时间，并在结束或取消时释放控制权。Dash 在动作 roguelike 中很常见，应该作为复用 Action，而不是写死在 PlayerMovement 里。

## 设计目的

将 Dash 行为封装为可配置的 Action，通过 ActionContext 的 direction 决定冲刺方向，通过 duration 和 speed 控制冲刺效果。Dash 结束后自动归零速度，状态机可在 completed 信号后恢复移动状态。

## 文件

`res://addons/mkit/kernel/actions/builtin/dash_action.gd`

## 字段说明

- **duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **speed**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **direction**：方向。例：玩家按右方向释放火球，direction=Vector2.RIGHT。

## 接口

```gdscript
class_name DashAction
extends GameAction
var duration: float = 0.18
var speed: float = 480.0
var direction: Vector2 = Vector2.ZERO
```

## 函数使用场景

此类通过重写 GameAction 内部回调工作：
- **_on_start()**：设置 action_id="dash"，配置 cancel_tags=["stun", "death"]，从 context.direction 初始化方向。
- **_on_update()**：每帧推动 source 的 CharacterBody2D.velocity 并调用 move_and_slide，到达 duration 时调用 complete。
- **_on_complete()**：将 source 速度归零。

## 使用示例

### 处理 Dash 命令

```gdscript
func handle_dash_command(command: GameCommand) -> void:
    var dash := DashAction.new()
    dash.duration = 0.18
    dash.speed = 520.0

    var ctx := ActionContext.from_command(command, owner_entity, null)
    ctx.source = owner_entity

    ServiceRegistry.get_service("actions").start_action(dash, ctx)
```
