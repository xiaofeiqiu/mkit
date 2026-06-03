# DialogueUI

## 概念说明

DialogueUI 是对话的展示层 Control，订阅 DialogueController 的信号显示台词与选项按钮。它与 RewardSelectionUI / ShopUI 同层同风格，只做呈现，不持有对话逻辑。

## 设计目的

把「对话怎么走」（DialogueController）与「对话怎么显示」（DialogueUI）分离。UI 通过 bind() 订阅控制器信号：node_entered 时刷新说话人与台词、choices_presented 时生成选项按钮（点击回调 controller.choose(i)）、dialogue_ended 时收起。游戏侧可替换或扩展 UI 而不动控制器。

## 文件

`res://addons/mkit/modules/ui/dialogue_ui.gd`

## 字段说明

- **controller**：绑定的 DialogueController；bind() 时设置并连接其信号。

预期子节点（缺失时对应刷新被跳过，便于裁剪）：`SpeakerLabel`（Label，显示 speaker_id）、`TextLabel`（Label，显示台词）、`ChoiceContainer`（选项按钮容器）。

## 接口

```gdscript
class_name DialogueUI
extends Control
var controller: DialogueController = null
func bind(dialogue_controller: DialogueController) -> void
```

## 函数使用场景

- **`bind(dialogue_controller)`**：把 UI 接到一个 DialogueController，连接 node_entered / choices_presented / dialogue_ended 信号（去重连接，可重复调用）。绑定后无需再手动刷新，UI 随信号自动更新。

内部信号处理：node_entered 刷新 SpeakerLabel / TextLabel 并清空旧选项；choices_presented 为每个可用选项生成一个 Button（pressed 回调 controller.choose(index)）；dialogue_ended 清空选项并隐藏自身。

## 使用示例

```gdscript
var dialogue := ServiceRegistry.get_service("dialogue") as DialogueController
var ui := preload("res://game/ui/dialogue_ui.tscn").instantiate() as DialogueUI
add_child(ui)
ui.bind(dialogue)
dialogue.start("dlg.elder_intro", GameplayContext.new())
```
