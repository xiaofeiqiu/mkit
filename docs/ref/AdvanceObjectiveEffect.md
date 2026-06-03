# AdvanceObjectiveEffect

## 概念说明

AdvanceObjectiveEffect 是任务模块内的 GameEffect，用于直接推进某个任务目标。它适合对话节点、交互、脚本事件或特殊机制显式 mark objective progress。

## 设计目的

提供不依赖 DomainEvent 匹配的任务推进入口，同时仍保持在 EffectExecutor 管线中执行。

## 文件

`res://addons/mkit/modules/quest/advance_objective_effect.gd`

## 字段说明

- **quest_id**：要推进的任务 ID。
- **objective_id**：要推进的目标 ID。
- **amount**：推进数量。必须大于 0。

## 接口

```gdscript
class_name AdvanceObjectiveEffect
extends GameEffect
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var amount: int = 1
```

## 函数使用场景

- **`_apply_impl(context)`**：通过 `quest` service 调用 QuestSystem.advance_objective。任务或目标不存在、任务未 active、amount 无效、缺少 quest service 或进度未变化时返回 EffectResult.fail；成功时返回包含 quest_id、objective_id 和 amount 的 EffectResult.ok。

## 使用示例

```gdscript
var effect := AdvanceObjectiveEffect.new()
effect.quest_id = "quest.intro"
effect.objective_id = "obj.talk"
effect.amount = 1
effect.apply(GameplayContext.new())
```
