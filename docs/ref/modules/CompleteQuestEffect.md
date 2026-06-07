# CompleteQuestEffect

**层：** Module  
**文件：** `addons/mkit/modules/quest/complete_quest_effect.gd`  
**继承：** `extends GameEffect`

## 职责

完成或交付任务。`turn_in=true` 时会尽量从 active → completed → turned_in 一步走完，并执行任务奖励 effect。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_id` | `String`（@export）| `""` | 任务 ID |
| `turn_in` | `bool`（@export）| `true` | 是否在完成后立刻交付并领取奖励 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context: GameplayContext) -> EffectResult` | `EffectResult` | 调 `QuestService.complete_quest()` / `turn_in_quest()` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var effect := CompleteQuestEffect.new()
effect.quest_id = "quest.first_hunt"
effect.turn_in = true
effect.apply(GameplayContext.new())
```

### 典型场景（Level 2）

```gdscript
func turn_in_to_npc(player: Node, npc: Node) -> void:
    var effect := CompleteQuestEffect.new()
    effect.quest_id = "quest.first_hunt"
    effect.turn_in = true
    var ctx := GameplayContext.new()
    ctx.source = player
    ctx.target = npc
    var result: EffectResult = effect.apply(ctx)
    if not result.success:
        push_warning(result.reason)
```

## 相关

- → [QuestService](QuestService.md) · [QuestDefinition](QuestDefinition.md) · [AcceptQuestEffect](AcceptQuestEffect.md)
- → [pipeline.md — Quest Lifecycle](../../pipeline.md#12-quest-lifecycle)

