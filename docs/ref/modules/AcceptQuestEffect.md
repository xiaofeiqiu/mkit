# AcceptQuestEffect

**层：** Module  
**文件：** `addons/mkit/modules/quest/accept_quest_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果链中的接任务 effect。读取 `quest_id`，通过 `"quest"` 服务调用 `QuestService.accept_quest()`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_id` | `String`（@export）| `""` | 要接受的 `QuestDefinition.quest_id` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context: GameplayContext) -> EffectResult` | `EffectResult` | 缺少 quest id / quest 服务 / 不可接受时失败；成功返回 `{quest_id}` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var effect := AcceptQuestEffect.new()
effect.quest_id = "quest.first_hunt"
var result: EffectResult = effect.apply(GameplayContext.new())
```

### 典型场景（Level 2）

```gdscript
func accept_from_dialogue(player: Node) -> void:
    var effect := AcceptQuestEffect.new()
    effect.quest_id = "quest.first_hunt"
    var ctx := GameplayContext.new()
    ctx.source = player
    var result: EffectResult = effect.apply(ctx)
    if not result.success:
        push_warning(result.reason)
```

## 相关

- → [QuestService](QuestService.md) · [QuestDefinition](QuestDefinition.md) · [GameEffect](../kernel/GameEffect.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md) · [pipeline.md — Quest Lifecycle](../../pipeline.md#12-quest-lifecycle)

