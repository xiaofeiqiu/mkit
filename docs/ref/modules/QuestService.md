# QuestService

**层：** Module  
**文件：** `addons/mkit/modules/quest/quest_service.gd`  
**继承：** `extends Saveable`  
**服务 ID：** `"quest"`

## 职责

任务运行系统。接取、自动监听领域事件推进目标、完成 / 交付任务、执行奖励 effect，并把 `QuestLog` 作为 `Saveable` 自动存档。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `log` | `QuestLog` | `QuestLog.new()` | 所有任务状态 |
| `content` | `ContentService` | `null` | 查询 `QuestDefinition` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `can_accept(quest_id: String, context: GameplayContext) -> bool` | `bool` | 检查定义、重复状态、前置任务和接取条件 |
| `accept_quest(quest_id: String, context: GameplayContext) -> bool` | `bool` | 创建/重置 active 状态并发事件 |
| `notify_event(event: DomainEvent) -> void` | — | 匹配 active 任务目标并推进 |
| `advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool` | `bool` | 手动推进目标 |
| `is_quest_complete(quest_id: String) -> bool` | `bool` | 所有非 optional 目标是否达成 |
| `complete_quest(quest_id: String, context: GameplayContext) -> bool` | `bool` | active → completed；auto_complete 定义会继续 turn in |
| `turn_in_quest(quest_id: String, context: GameplayContext) -> bool` | `bool` | 执行奖励 effect，completed → turned_in / available |
| `get_definition(quest_id: String) -> QuestDefinition` | `QuestDefinition` | 从 `ContentService` 查定义 |
| `get_state(quest_id: String) -> QuestState` | `QuestState` | 从 log 查状态 |
| `to_save_data() -> Dictionary` | `Dictionary` | 代理 `log.to_save_data()` |
| `from_save_data(data: Dictionary) -> void` | — | 代理 `log.from_save_data(data)` |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `quest_offered` | `quest_id` | 预留信号，当前源码未主动发出 |
| `quest_accepted` | `quest_id` | 接取成功 |
| `objective_advanced` | `quest_id, objective_id, current, required` | 目标推进 |
| `quest_completed` | `quest_id` | 任务完成 |
| `quest_turned_in` | `quest_id` | 交付完成 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var quest: QuestService = ServiceRegistry.get_service("quest") as QuestService
var ctx := GameplayContext.new()
quest.accept_quest("quest.first_hunt", ctx)
```

### 典型场景（Level 2）

```gdscript
func accept_and_watch(quest_id: String, player: Node) -> void:
    var quest: QuestService = ServiceRegistry.get_service("quest") as QuestService
    if quest == null:
        return
    quest.objective_advanced.connect(func(id: String, obj: String, current: int, required: int) -> void:
        print("%s/%s %d/%d" % [id, obj, current, required])
    )
    var ctx := GameplayContext.new()
    ctx.source = player
    if not quest.can_accept(quest_id, ctx):
        return
    quest.accept_quest(quest_id, ctx)
```

## 相关

- → [QuestDefinition](QuestDefinition.md) · [QuestObjectiveDefinition](QuestObjectiveDefinition.md) · [QuestLog](QuestLog.md)
- → [EventService](../kernel/EventService.md) · [Saveable](../kernel/Saveable.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md) · [pipeline.md — Quest Lifecycle](../../pipeline.md#12-quest-lifecycle)

