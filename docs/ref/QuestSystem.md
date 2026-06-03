# QuestSystem

## 概念说明

QuestSystem 是任务域服务，注册为 ServiceRegistry 的 `quest` service。它负责接取任务、监听事件推进 objective、完成任务、turn-in 发奖和保存 QuestLog。

## 设计目的

让任务成为事件驱动的通用机制。战斗、背包、对话、世界导航和脚本都只需要发 DomainEvent 或调用公开 API，QuestSystem 统一处理任务状态与奖励。

## 文件

`res://addons/mkit/modules/quest/quest_system.gd`

## 字段说明

- **quest_offered**：预留信号。当前实现未主动发出，供后续 NPC/UI offer 流程扩展。
- **quest_accepted**：任务接取成功时发出。
- **objective_advanced**：目标进度实际变化时发出，携带当前值和 required_count。
- **quest_completed**：任务从 active 进入 completed 时发出。
- **quest_turned_in**：奖励 effects 成功并写入最终任务状态后发出；repeatable 任务会先重置为 available。
- **log**：QuestLog 实例，保存所有任务运行状态。
- **content**：ContentRegistry 引用。为空时 QuestSystem 会尝试从 ServiceRegistry 的 `content` service 懒加载。

## 接口

```gdscript
class_name QuestSystem
extends Saveable
signal quest_offered(quest_id: String)
signal quest_accepted(quest_id: String)
signal objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)
var log: QuestLog = QuestLog.new()
var content: ContentRegistry = null
func can_accept(quest_id: String, context: GameplayContext) -> bool
func accept_quest(quest_id: String, context: GameplayContext) -> bool
func notify_event(event: DomainEvent) -> void
func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool
func is_quest_complete(quest_id: String) -> bool
func complete_quest(quest_id: String, context: GameplayContext) -> bool
func turn_in_quest(quest_id: String, context: GameplayContext) -> bool
func get_definition(quest_id: String) -> QuestDefinition
func get_state(quest_id: String) -> QuestState
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`can_accept(quest_id, context)`**：对话、NPC 或 UI 在显示接任务选项前检查前置任务和 accept_conditions。
- **`accept_quest(quest_id, context)`**：接取任务并记录 context，发出 QuestSystem 和 EventRouter 的 accepted 事件。
- **`notify_event(event)`**：EventRouter.domain_event_emitted 或桥接出的 domain event 到达时推进匹配目标；带 `change_type="added"` 的 inventory_changed 会桥接为 item_acquired，并把 `quantity` 映射为 `amount`。
- **`advance_objective(quest_id, objective_id, amount)`**：脚本或 AdvanceObjectiveEffect 直接推进指定目标；任务未 active、目标不存在、amount <= 0 或已达上限时返回 false。
- **`is_quest_complete(quest_id)`**：检查所有非 optional 目标是否达到 required_count。
- **`complete_quest(quest_id, context)`**：把 active 任务标为 completed；auto_complete 任务会继续 turn_in。
- **`turn_in_quest(quest_id, context)`**：执行 reward_effects，全部成功后标记 turned_in，repeatable 任务回到 available，然后发出 quest_turned_in；奖励失败时保持 completed 并返回 false。
- **`get_definition(quest_id)`**：从 ContentRegistry 读取 QuestDefinition；quest_id 为空或内容缺失时返回 null。
- **`get_state(quest_id)`**：读取 QuestLog 中的 QuestState。
- **`to_save_data()` / `from_save_data(data)`**：作为 Saveable 由 SaveManager 自动收集和恢复。

## 使用示例

```gdscript
var quest := ServiceRegistry.get_service("quest") as QuestSystem
var ctx := GameplayContext.new().with_source(player)
if quest.can_accept("quest.intro", ctx):
    quest.accept_quest("quest.intro", ctx)
```
