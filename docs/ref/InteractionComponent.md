# InteractionComponent

## 概念说明

InteractionComponent 是实体寻找并触发互动对象的 Area2D 组件。它追踪当前聚焦对象、发出 UI 提示信号并构造 GameplayContext 调用 interact。键鼠、手柄、触屏、AI 或教程脚本都应该能走同一套互动逻辑。

## 设计目的

把"检测附近可互动对象、显示提示、触发互动"的逻辑封装到独立组件，使输入层只需调用 `try_interact()`，UI 层只需监听信号，不需要自己管理 Interactable 的查找和 GameplayContext 的构建。

## 文件

`res://addons/mkit/modules/interaction/interaction_component.gd`

## 字段说明

- **current_interactable**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name InteractionComponent
extends Area2D
signal interactable_focused(interactable: Interactable)
signal interactable_unfocused(interactable: Interactable)
var current_interactable: Interactable = null
func try_interact() -> bool
```

## 函数使用场景

- **`try_interact()`**：输入层（玩家按 E 键）调用的入口。构造 GameplayContext（source=owner，target=interactable.owner），调用 `current_interactable.interact()`，返回是否成功。无聚焦对象时返回 false。
- **`interactable_focused` 信号**：进入检测范围时发出，HUD 接收后显示提示（如 "Press E to interact"）。
- **`interactable_unfocused` 信号**：离开检测范围时发出，HUD 接收后隐藏提示。

## 使用示例

### Player 按 E 交互

```gdscript
func _process(delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        var interaction := $Components/InteractionComponent as InteractionComponent
        interaction.try_interact()
```

### UI 显示交互提示

```gdscript
func _ready() -> void:
    var interaction := $Components/InteractionComponent as InteractionComponent
    interaction.interactable_focused.connect(_on_focus)
    interaction.interactable_unfocused.connect(_on_unfocus)

func _on_focus(interactable: Interactable) -> void:
    $HUD.show_prompt(interactable.display_text)

func _on_unfocus(interactable: Interactable) -> void:
    $HUD.hide_prompt()
```
