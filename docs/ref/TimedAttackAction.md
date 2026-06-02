# TimedAttackAction

## 概念说明

TimedAttackAction 是带前摇、生效和后摇窗口的攻击 Action。只在 active window 打开 hitbox，结束后通知状态机回到可行动状态。动作 RPG 的近战攻击需要清晰的时间窗口，否则手感和判定都很难调。

## 设计目的

将攻击分为 startup（前摇）、active（有效帧）、recovery（后摇）三段，精确控制 hitbox 开关时机。通过 `cancel_tags` 配置允许被哪些行为打断，支持攻击取消接其他动作。

## 文件

`res://addons/mkit/kernel/actions/builtin/timed_attack_action.gd`

## 字段说明

- **startup_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **active_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **recovery_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **hitbox_path**：资源或节点路径。例：用 hitbox_path 指向场景或节点，方便在 Inspector 中配置。

## 接口

```gdscript
class_name TimedAttackAction
extends GameAction
var startup_duration: float = 0.12
var active_duration: float = 0.10
var recovery_duration: float = 0.25
var hitbox_path: NodePath = NodePath("Components/HitboxComponent")
```

## 函数使用场景

此类通过重写 GameAction 的内部回调工作：
- **_on_start()**：设置 action_id 和 cancel_tags，播放攻击动画，关闭 hitbox。
- **_on_update()**：根据 elapsed 时间进入前摇 → 开启 hitbox → 关闭 hitbox → 完成的流程。
- **_on_cancel()**：立即关闭 hitbox。
- **_on_complete()**：关闭 hitbox，发出 completed 信号让状态机回到 Idle。

## 使用示例

### 配置并启动基础攻击

```gdscript
func start_basic_attack(player: Node) -> void:
    var action := TimedAttackAction.new()
    action.startup_duration = 0.12
    action.active_duration = 0.08
    action.recovery_duration = 0.25
    action.hitbox_path = NodePath("Components/HitboxComponent")

    var ctx := ActionContext.new()
    ctx.source = player
    ctx.direction = Vector2.RIGHT

    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(action, ctx)
```
