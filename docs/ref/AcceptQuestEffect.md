# AcceptQuestEffect

## 概念说明

AcceptQuestEffect 是任务模块内的 GameEffect，用于通过 EffectExecutor 接取任务。对话选项、交互对象或脚本可以把它放入 effects 列表，让接任务行为走统一 effect 管线。

## 设计目的

把“接取任务”做成可配置 effect，使 DialogueChoice、Interactable 或其他数据驱动入口不需要直接依赖 QuestSystem 细节。

## 文件

`res://addons/mkit/modules/quest/accept_quest_effect.gd`

## 字段说明

- **quest_id**：要接取的 QuestDefinition ID。

## 接口

```gdscript
class_name AcceptQuestEffect
extends GameEffect
@export var quest_id: String = ""
```

## 函数使用场景

- **`_apply_impl(context)`**：通过 ServiceRegistry 获取 `quest` service，调用 QuestSystem.accept_quest。缺少 quest_id、缺少 service 或接取失败时返回 EffectResult.fail；成功时返回包含 quest_id 的 EffectResult.ok。

## 使用示例

```gdscript
var effect := AcceptQuestEffect.new()
effect.quest_id = "quest.intro"
effect.apply(GameplayContext.new().with_source(player))
```
