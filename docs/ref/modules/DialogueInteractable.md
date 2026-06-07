# DialogueInteractable

**层：** Module  
**文件：** `addons/mkit/modules/dialogue/dialogue_interactable.gd`  
**继承：** `extends Interactable`

## 职责

把"交互"接到"对话"的桥。挂在 NPC 交互 `Area2D` 下（命名 `Interactable`），被交互时调 `DialogueService.start(dialogue_id, ...)`，并发 `EventService.npc_talked`。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `dialogue_id` | `String` | `""` | 要开始的对话 |
| `npc_id` | `String` | `""` | 发 `npc_talked` 用的 NPC id |

继承自 `Interactable` 的 `display_text` / `conditions` 同样可用。

## 使用模式

### 最小示例（Level 1）

```gdscript
# NPC/InteractArea/Interactable (DialogueInteractable)：
#   dialogue_id = "dialogue.elder_intro", npc_id = "npc.elder"
```

## 相关

- → [Interactable](Interactable.md) · [DialogueService](DialogueService.md)
- → [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)
