# CompleteQuestEffect

## 概念说明

CompleteQuestEffect 是任务模块内的 GameEffect，用于完成或提交任务。它可以只把任务从 active 变成 completed，也可以继续 turn-in 并发放奖励。

## 设计目的

让 NPC 对话、交互或脚本可以用数据驱动方式完成任务，不需要直接写 QuestSystem 调用。

## 文件

`res://addons/mkit/modules/quest/complete_quest_effect.gd`

## 字段说明

- **quest_id**：要完成或提交的任务 ID。
- **turn_in**：为 true 时尝试提交并发放奖励；为 false 时只执行 complete_quest。

## 接口

```gdscript
class_name CompleteQuestEffect
extends GameEffect
@export var quest_id: String = ""
@export var turn_in: bool = true
```

## 函数使用场景

- **`_apply_impl(context)`**：通过 `quest` service 调用 QuestSystem.complete_quest；`turn_in` 为 true 时，如果任务已 completed 会直接调用 QuestSystem.turn_in_quest，否则先 complete，再在状态仍为 completed 时 turn_in。缺少 quest_id、缺少 service 或状态转换失败时返回 EffectResult.fail。

## 使用示例

```gdscript
var effect := CompleteQuestEffect.new()
effect.quest_id = "quest.intro"
effect.turn_in = true
effect.apply(GameplayContext.new().with_source(player))
```
