# DialogueService

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"dialogue"`

## 职责

对话运行时状态机。`start` 开始一段对话，`_enter_node` 推进节点（跑 `on_enter_effects`、求值选项），`choose`/`advance` 前进，`end` 结束。同一时间只允许一段对话。

## 字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `runtime` | `DialogueRuntime` | 当前对话运行时（无对话时为 `null`）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `start(dialogue_id, context) -> bool` | `bool` | 开始；已有对话进行中返回 false |
| `is_active() -> bool` | `bool` | 是否进行中 |
| `get_available_choices() -> Array[DialogueChoice]` | — | 当前节点条件通过的选项 |
| `choose(choice_index: int) -> void` | — | 选第 index 个**可用**选项，跑其 effects，进下一节点 |
| `advance() -> void` | — | 无选项节点前进到 `next_node_id` |
| `end() -> void` | — | 结束并发 `dialogue_ended` |

## 信号

`dialogue_started(id)` · `node_entered(node)` · `choices_presented(node, available)` · `dialogue_ended(id)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
var ctx := GameplayContext.new()
ctx.source = player
dialogue.start("dialogue.elder_intro", ctx)
```

### 典型场景（Level 2）

```gdscript
# 简易对话推进控制（无 UI 也能跑）
func _ready() -> void:
    var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
    dialogue.node_entered.connect(func(node: DialogueNode):
        print("%s: %s" % [node.speaker_id, node.text])
    )
    dialogue.choices_presented.connect(func(_node: DialogueNode, available: Array[DialogueChoice]):
        for i in available.size():
            print("  [%d] %s" % [i, available[i].text])
    )
    dialogue.dialogue_ended.connect(func(id: String): print("结束: %s" % id))


func _on_choice_key(index: int) -> void:
    var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
    if not dialogue.is_active():
        return
    if dialogue.get_available_choices().is_empty():
        dialogue.advance()          # 文本节点：直接前进
    else:
        dialogue.choose(index)      # 选项节点：选一个
```

## 相关

- → [DialogueDefinition](DialogueDefinition.md) · [DialogueNode](DialogueNode.md) · [DialogueChoice](DialogueChoice.md) · [DialogueRuntime](DialogueRuntime.md)
- → [pipeline.md — Dialogue](../../pipeline.md#15-dialogue) · [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)
