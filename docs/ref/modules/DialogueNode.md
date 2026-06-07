# DialogueNode

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_node.gd`  
**继承：** `extends Resource`

## 职责

对话树的一个节点：一句台词 + 进入时的副作用 + 选项或直连下一节点。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `node_id` | `String` | `""` | 节点 id |
| `speaker_id` | `String` | `""` | 说话者 |
| `text` | `String` | `""` | 台词（multiline）|
| `on_enter_effects` | `Array[GameEffect]` | `[]` | 进入时触发 |
| `choices` | `Array[DialogueChoice]` | `[]` | 选项（非空则等待选择）|
| `next_node_id` | `String` | `""` | 无选项时的下一节点；空则对话结束 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# node：speaker_id="村长", text="...", choices=[...] 或 next_node_id="info"
```

## 相关

- → [DialogueDefinition](DialogueDefinition.md) · [DialogueChoice](DialogueChoice.md)
