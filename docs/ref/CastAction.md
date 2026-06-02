# CastAction

## 概念说明

CastAction 是带施法时间、可取消和完成回调的 Action。负责推进 cast_time，期间播放施法表现，完成后通知 AbilityController 执行效果。AbilityController 已经支持 `cast_time`，但没有 CastAction 时，读条、打断、暂停和完成顺序都没有统一落点。

## 设计目的

将施法时间过程统一管理，确保被眩晕打断时不执行技能效果，暂停时不推进施法进度，完成后通过 completed 信号触发 AbilityController 执行效果列表。

## 文件

`res://addons/mkit/kernel/actions/builtin/cast_action.gd`

## 字段说明

- **duration**：施法时间。例：火球 cast_time=0.35，期间被眩晕会取消。
- **animation_name**：施法动画名。例：法师播放 cast 动画直到 Action 完成或取消。

## 接口

```gdscript
class_name CastAction
extends GameAction
var duration: float = 0.0
var animation_name: String = "cast"
```

## 函数使用场景

此类通过重写 GameAction 内部回调工作：
- **_on_start()**：设置 cancel_tags=["stun", "death", "silence"]，播放施法动画。
- **_on_update()**：推进 elapsed，到达 duration 时调用 complete。
- **_on_cancel()**：停止施法反馈（如读条 UI 或角色动画）。
- **_on_complete()**：通知 source 节点的 `on_cast_action_finished` 回调（如果存在）。

## 使用示例

### 在 AbilityController 中启动施法

```gdscript
var action := CastAction.new()
action.duration = fireball_definition.cast_time
action.completed.connect(func(_action):
    _execute_ability_effects(fireball_definition, ctx)
)

var action_context := ActionContext.new()
action_context.source = player
action_context.ability_id = "ability.fireball_basic"
ServiceRegistry.get_service("actions").start_action(action, action_context)
```
