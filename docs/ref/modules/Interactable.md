# Interactable

**层：** Module  
**文件：** `addons/mkit/modules/interaction/interactable.gd`  
**继承：** `extends Node`

## 职责

可交互对象基类。`InteractionComponent` 检测到它后调 `interact()`，先过 `conditions` 再执行 `_interact_impl()`。子类（`DialogueInteractable`、`Portal`）override `_interact_impl`。须命名为 `Interactable` 挂在交互 `Area2D` 下。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `interaction_id` | `String` | `""` | 标识 |
| `display_text` | `String` | `"Interact"` | 提示文案（"交谈"/"打开"）|
| `conditions` | `Array[Condition]` | `[]` | 交互门槛 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `can_interact(context) -> bool` | `bool` | 条件是否满足 |
| `interact(context) -> bool` | `bool` | 过条件后调 `_interact_impl` |
| `_interact_impl(context) -> bool` | `bool` | **子类实现** 实际交互逻辑，默认 `true` |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name ChestInteractable
extends Interactable

func _interact_impl(context: GameplayContext) -> bool:
    print("打开宝箱")
    return true
```

## 相关

- → [InteractionComponent](InteractionComponent.md) · [DialogueInteractable](DialogueInteractable.md) · [Portal](Portal.md)
- → [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)
