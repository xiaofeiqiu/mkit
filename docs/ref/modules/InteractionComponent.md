# InteractionComponent

**层：** Module  
**文件：** `addons/mkit/modules/interaction/interaction_component.gd`  
**继承：** `extends Area2D`

## 职责

挂在玩家身上的交互探测器。进入/离开某个 `Area2D`（其下有名为 `Interactable` 的子节点）时聚焦/失焦，按交互键时 `try_interact()` 触发当前聚焦对象。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `current_interactable` | `Interactable` | `null` | 当前聚焦的可交互对象 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `try_interact() -> bool` | `bool` | 触发当前聚焦对象的 `interact()`，无则 false |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `interactable_focused` | `interactable` | 进入交互范围（可显示"按 E"提示）|
| `interactable_unfocused` | `interactable` | 离开范围 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 输入里触发
if Input.is_action_just_pressed("interact"):
    (player.get_node("InteractionComponent") as InteractionComponent).try_interact()
```

## 相关

- → [Interactable](Interactable.md) · [cookbook/09_npc_dialogue.md](../../cookbook/09_npc_dialogue.md)
