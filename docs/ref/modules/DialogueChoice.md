# DialogueChoice

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_choice.gd`  
**继承：** `extends Resource`

## 职责

对话节点上的一个分支选项：文本、跳转目标、出现条件、选择后的副作用。`effects` 是把"对话后果"（接任务、给物品）接进系统的地方。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `text` | `String` | `""` | 选项文本（multiline）|
| `next_node_id` | `String` | `""` | 选后跳转；空则结束对话 |
| `conditions` | `Array[Condition]` | `[]` | 决定该选项是否出现 |
| `effects` | `Array[GameEffect]` | `[]` | 选择后执行（如 `AcceptQuestEffect`）|

## 使用模式

### 最小示例（Level 1）

```gdscript
# choice：text="我来帮忙", next_node_id="info",
#         effects=[AcceptQuestEffect(quest_id="quest.cull_beasts")]
```

## 相关

- → [DialogueNode](DialogueNode.md) · [DialogueService](DialogueService.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md)（在选项里接任务）
