# DialogueDefinition

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

一段对话的静态定义（`.tres`）：起始节点 + 节点列表。`DialogueService` 按 `start_node_id` 进入并按节点的 `next_node_id` / 选项推进。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `dialogue_id` | `String` | `""` | 唯一 id |
| `start_node_id` | `String` | `""` | 起始节点 id |
| `nodes` | `Array[DialogueNode]` | `[]` | 所有节点 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_node(node_id) -> DialogueNode` | — | 按 id 查节点 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# .tres：dialogue_id="dialogue.elder_intro", start_node_id="greet",
#         nodes=[greet, info, bye]
```

## 相关

- → [DialogueNode](DialogueNode.md) · [DialogueChoice](DialogueChoice.md) · [DialogueService](DialogueService.md)
- → [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)
