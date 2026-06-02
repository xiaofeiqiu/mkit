# EventRouter

## 概念说明

EventRouter 是玩法事件发布和订阅的路由层。负责发布 damage_applied、entity_died、inventory_changed、room_cleared、reward_selected、run_started、run_finished 等事件，并保留最近事件供调试查看。UI、音效、VFX、Analytics 和 Debug 都需要知道发生了什么，但不应该直接依赖 Combat、Inventory 或 Room 的内部实现。

## 设计目的

作为核心发布-订阅中心，使玩法系统与表现层完全解耦。Combat 不直接播放音效，Room 不直接读取 Combat 内部状态，所有跨域通信通过 EventRouter 进行。

## 文件

`res://addons/mkit/kernel/events/event_router.gd`

## 字段说明

- **recent_events**：最近事件列表。例：DebugOverlay 显示最近 damage_applied、entity_died、room_cleared，方便排查流程。
- **max_recent_events**：最近事件保留上限。例：只保留 100 条，避免长期运行后 Debug 数据无限增长。

## 接口

```gdscript
class_name EventRouter
extends Node
signal domain_event_emitted(event: DomainEvent)
signal damage_applied(result)
signal entity_died(entity_id: String, entity_ref: Node)
signal inventory_changed(owner_id: String)
signal room_cleared(room_id: String)
signal reward_selected(reward_id: String)
signal run_started(run_id: String, seed: int)
signal run_finished(run_id: String, result: String)
var recent_events: Array[DomainEvent] = []
var max_recent_events: int = 100
func emit_domain_event(event: DomainEvent) -> void
func emit_damage_applied(result) -> void
func emit_entity_died(entity_id: String, entity_ref: Node) -> void
func emit_inventory_changed(owner_id: String) -> void
func emit_room_cleared(room_id: String) -> void
func emit_reward_selected(reward_id: String, source_id: String = "") -> void
func emit_run_started(run_id: String, seed: int) -> void
func emit_run_finished(run_id: String, result: String) -> void
```

## 函数使用场景

- **emit_domain_event()**：通用事件发射入口。例：任何系统都可以通过它发出自定义事件，同时将其记录在 `recent_events` 中供调试查看。
- **emit_damage_applied()**：伤害应用事件。例：HealthComponent 应用 DamageResult 后调用此方法，FeedbackSystem 监听以播放受击音效和数字。
- **emit_entity_died()**：实体死亡事件。例：HealthComponent 确认 HP 归零后调用，RoomController 监听以更新活跃敌人计数，FeedbackSystem 监听以播放死亡特效。
- **emit_inventory_changed()**：背包变化事件。例：InventoryController 添加或移除物品后调用，HUD 监听以刷新背包图标。
- **emit_item_collected()**：物品拾取事件。例：拾取成功进入背包后发出，Analytics 记录拾取行为。
- **emit_room_cleared()**：房间清理完成事件。例：RoomController 检测所有敌人死亡后发出，RunDirector 监听以推进到奖励选择阶段。
- **emit_reward_selected()**：玩家选择奖励事件。例：RewardSystem 应用玩家选择后发出，Analytics 记录选择行为。
- **emit_run_started()**：Run 开始事件。例：RunDirector 创建 RunState 后发出，Analytics 记录 run 开始。
- **emit_run_finished()**：Run 结束事件。例：RunDirector 完成或失败一局后发出，结算界面监听以显示结果。

## 使用示例

### 监听伤害事件

```gdscript
func _ready() -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    events.damage_applied.connect(_on_damage_applied)
    events.entity_died.connect(_on_entity_died)

func _on_damage_applied(result: DamageResult) -> void:
    print("Damage applied: ", result.final_amount)

func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
    print("Entity died: ", entity_id)
```

### 发出房间清理事件

```gdscript
func on_all_enemies_dead() -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_room_cleared("room_001")
```
