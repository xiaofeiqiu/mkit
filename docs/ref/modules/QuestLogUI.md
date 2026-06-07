# QuestLogUI

**层：** Module  
**文件：** `addons/mkit/modules/ui/quest_log_ui.gd`  
**继承：** `extends Control`

## 职责

任务列表 UI。绑定 `QuestService` 后监听任务信号，渲染 `QuestContainer` 下的任务标题、状态和 objective 进度。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `quest_system` | `QuestService` | `null` | 已绑定任务服务 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `bind(system: QuestService) -> void` | — | 连接任务信号并刷新 |
| `refresh() -> void` | — | 清空并重绘 `QuestContainer` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var quest: QuestService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_QUEST) as QuestService
$QuestLogUI.bind(quest)
```

### 典型场景（Level 2）

```gdscript
func toggle_quest_log() -> void:
    var ui := $QuestLogUI as QuestLogUI
    var quest: QuestService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_QUEST) as QuestService
    if quest == null:
        return
    ui.bind(quest)
    ui.visible = not ui.visible
```

## 相关

- → [QuestService](QuestService.md) · [QuestState](QuestState.md) · [QuestDefinition](QuestDefinition.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md)

