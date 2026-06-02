# RewardSelectionUI

## 概念说明

RewardSelectionUI 是奖励选择界面。它展示奖励选项并把玩家选择传给 RunDirector 或 RewardSystem。它是清房间后选择升级这一核心体验的可视层。

## 设计目的

把奖励的展示逻辑（渲染按钮、显示文本和图标）与奖励的应用逻辑（EffectExecutor 执行效果）分离，UI 只负责呈现和提交选择，实际效果由 RewardSystem 和 RunDirector 处理。

## 文件

`res://addons/mkit/modules/ui/reward_selection_ui.gd`

## 字段说明

- **options**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **run_director**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name RewardSelectionUI
extends Control
var options: Array[RewardOption] = []
var run_director: RunDirector = null
func setup(data: Dictionary) -> void
```

## 函数使用场景

- **`setup(data)`**：UIManager 打开屏幕时调用，从 data 中读取 options 列表和 run_director 引用，并调用 `_render_options()` 生成按钮。
- **`_render_options()`**：内部方法，遍历 options 列表为每个 RewardOption 创建一个 Button，按钮文本显示 display_name 和 description，按下时调用 `_on_option_selected()`。
- **`_on_option_selected(option)`**：内部方法，玩家点击一个奖励按钮后：调用 RunDirector.select_reward(option)，再通过 UIManager 关闭 "reward_selection" 屏幕（自动恢复 gameplay 时间）。

## 使用示例

```gdscript
func setup(data: Dictionary) -> void:
    options = data["options"]
    run_director = data["run_director"]
    _render_options()

func _render_options() -> void:
    for option in options:
        var button := Button.new()
        button.text = "%s\n%s" % [option.display_name, option.description]
        button.pressed.connect(func():
            run_director.select_reward(option)
            ServiceRegistry.get_service("ui").close_screen("reward_selection")
        )
        $OptionContainer.add_child(button)
```
