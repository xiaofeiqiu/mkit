# QuestLogUI

## 概念说明

QuestLogUI 是任务日志的展示层 Control，绑定 QuestSystem 后显示 QuestLog 中的任务状态与 objective 进度。它与 DialogueUI / ShopUI 同层，只做呈现，不持有任务推进、完成或发奖逻辑。

## 设计目的

把「任务怎么推进」（QuestSystem）与「任务怎么显示」（QuestLogUI）分离。UI 订阅 quest_accepted / objective_advanced / quest_completed / quest_turned_in 信号并自动刷新，让游戏侧可以直接复用默认任务日志，也可以替换成自己的界面而不影响任务系统。

## 文件

`res://addons/mkit/modules/ui/quest_log_ui.gd`

## 字段说明

- **quest_system**：绑定的 QuestSystem。bind() 会连接任务信号并立即 refresh()。

预期子节点（缺失时对应刷新被跳过，便于裁剪）：`QuestContainer`（用于生成任务行的容器）、`EmptyLabel`（QuestLog 为空时显示）。

## 接口

```gdscript
class_name QuestLogUI
extends Control
var quest_system: QuestSystem = null
func bind(system: QuestSystem) -> void
func refresh() -> void
```

## 函数使用场景

- **`bind(system)`**：打开任务日志界面或初始化 HUD 时调用，把 UI 绑定到 QuestSystem；重复绑定不同 QuestSystem 时会断开旧信号并连接新信号。
- **`refresh()`**：手动重绘任务列表；通常由 QuestSystem 的任务信号自动触发。它会清空 QuestContainer，按 quest_id 排序遍历 QuestLog.states，为每个任务生成标题、状态与 objective 进度 Label。

内部渲染规则：标题优先使用 QuestDefinition.display_name，缺失 definition 或 display_name 时回退到 quest_id；objective 文本优先使用 description，否则使用 objective_id，并显示 `current/required_count`。

## 使用示例

```gdscript
var quest := ServiceRegistry.get_service("quest") as QuestSystem
var ui := QuestLogUI.new()
add_child(ui)
ui.bind(quest)
```
