# DialogueUI

**层：** Module  
**文件：** `addons/mkit/modules/ui/dialogue_ui.gd`  
**继承：** `extends Control`

## 职责

最小对话 UI 控件。绑定 `DialogueService` 后，把当前节点文本写入 `SpeakerLabel` / `TextLabel`，并在 `ChoiceContainer` 里生成选项按钮。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `controller` | `DialogueService` | `null` | 已绑定的对话服务 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `bind(dialogue_controller: DialogueService) -> void` | — | 连接 `node_entered` / `choices_presented` / `dialogue_ended` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var dialogue: DialogueService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
$DialogueUI.bind(dialogue)
```

### 典型场景（Level 2）

```gdscript
func open_dialogue(dialogue_id: String, npc: Node, player: Node) -> void:
    var service: DialogueService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
    if service == null:
        return
    $DialogueUI.visible = true
    $DialogueUI.bind(service)
    service.start(dialogue_id, npc, player)
```

## 相关

- → [DialogueService](DialogueService.md) · [DialogueNode](DialogueNode.md) · [DialogueChoice](DialogueChoice.md)
- → [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)

