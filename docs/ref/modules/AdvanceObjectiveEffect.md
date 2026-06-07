# AdvanceObjectiveEffect

**层：** Module  
**文件：** `addons/mkit/modules/quest/advance_objective_effect.gd`  
**继承：** `extends GameEffect`

## 职责

手动推进指定任务目标。适合对话、交互、脚本触发等非自动事件目标。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_id` | `String`（@export）| `""` | 任务 ID |
| `objective_id` | `String`（@export）| `""` | 目标 ID |
| `amount` | `int`（@export）| `1` | 推进数量 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context: GameplayContext) -> EffectResult` | `EffectResult` | 调 `QuestService.advance_objective()`；失败时返回原因 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var effect := AdvanceObjectiveEffect.new()
effect.quest_id = "quest.first_hunt"
effect.objective_id = "talk_to_guard"
effect.apply(GameplayContext.new())
```

### 典型场景（Level 2）

```gdscript
func mark_npc_talked(npc: Node) -> void:
    var effect := AdvanceObjectiveEffect.new()
    effect.quest_id = "quest.first_hunt"
    effect.objective_id = "talk_to_guard"
    effect.amount = 1
    var ctx := GameplayContext.new()
    ctx.source = npc
    var result: EffectResult = effect.apply(ctx)
    if not result.success:
        push_warning(result.reason)
```

## 相关

- → [QuestService](QuestService.md) · [QuestObjectiveDefinition](QuestObjectiveDefinition.md) · [CompleteQuestEffect](CompleteQuestEffect.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md)

