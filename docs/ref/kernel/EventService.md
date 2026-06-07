# EventService

**层：** Kernel  
**文件：** `addons/mkit/kernel/events/event_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"events"`

## 职责

领域事件路由器。提供类型化的 `emit_*` 方法，将游戏事件广播为 GDScript 信号，供 UI、音频、VFX、分析等 module 订阅。同时维护 `recent_events` 供调试回放。

## 字段（public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `recent_events` | `Array[DomainEvent]` | `[]` | 最近 100 个领域事件（调试用）|
| `max_recent_events` | `int` | `100` | 容量上限 |

## 方法（emit_*）

| 方法签名 | 说明 |
|----------|------|
| `emit_domain_event(event: DomainEvent) -> void` | 发送任意领域事件（底层，其余 emit_* 均调此方法）|
| `emit_damage_applied(result: DamageResult) -> void` | 伤害结算后广播 |
| `emit_entity_died(entity_id: String, entity_ref: Node) -> void` | 实体死亡时广播 |
| `emit_inventory_changed(owner_id, item_id, quantity, change_type) -> void` | 背包变化时广播 |
| `emit_room_cleared(room_id: String) -> void` | 房间清空时广播 |
| `emit_reward_selected(reward_id: String, source_id: String) -> void` | 奖励选中时广播 |
| `emit_run_started(run_id: String, seed: int) -> void` | Run 开始时广播 |
| `emit_run_finished(run_id: String, result: String) -> void` | Run 结束时广播 |
| `emit_quest_accepted(quest_id: String) -> void` | 任务接受时广播 |
| `emit_quest_objective_advanced(quest_id, objective_id, current, required) -> void` | 目标推进时广播 |
| `emit_quest_completed(quest_id: String) -> void` | 任务完成时广播 |
| `emit_quest_turned_in(quest_id: String) -> void` | 任务上交时广播 |
| `emit_dialogue_started(dialogue_id: String) -> void` | 对话开始时广播 |
| `emit_dialogue_ended(dialogue_id: String) -> void` | 对话结束时广播 |
| `emit_npc_talked(npc_id: String) -> void` | 与 NPC 交谈时广播（`DialogueInteractable` 触发）|
| `emit_zone_changed(from_zone_id, to_zone_id) -> void` | 区域切换时广播 |
| `emit_item_purchased(shop_id, item_id, quantity) -> void` | 购买物品时广播 |
| `emit_item_sold(shop_id, item_id, quantity) -> void` | 出售物品时广播 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `domain_event_emitted` | `event: DomainEvent` | 任意 emit_* 调用后 |
| `damage_applied` | `result: DamageResult` | emit_damage_applied |
| `entity_died` | `entity_id: String, entity_ref: Node` | emit_entity_died |
| `inventory_changed` | `owner_id: String` | emit_inventory_changed |
| `room_cleared` | `room_id: String` | emit_room_cleared |
| `reward_selected` | `reward_id: String` | emit_reward_selected |
| `run_started` | `run_id: String, seed: int` | emit_run_started |
| `run_finished` | `run_id: String, result: String` | emit_run_finished |
| `quest_accepted` | `quest_id: String` | emit_quest_accepted |
| `quest_objective_advanced` | `quest_id, objective_id, current, required` | emit_quest_objective_advanced |
| `quest_completed` | `quest_id: String` | emit_quest_completed |
| `quest_turned_in` | `quest_id: String` | emit_quest_turned_in |
| `dialogue_started` | `dialogue_id: String` | emit_dialogue_started |
| `dialogue_ended` | `dialogue_id: String` | emit_dialogue_ended |
| `npc_talked` | `npc_id: String` | emit_npc_talked |
| `zone_changed` | `from_zone_id, to_zone_id` | emit_zone_changed |
| `item_purchased` | `shop_id, item_id, quantity` | emit_item_purchased |
| `item_sold` | `shop_id, item_id, quantity` | emit_item_sold |

## 使用模式

### 最小示例（Level 1）

```gdscript
var events := ServiceRegistry.get_service("events") as EventService
events.entity_died.connect(_on_entity_died)

func _on_entity_died(entity_id: String, _ref: Node) -> void:
    print("Dead: %s" % entity_id)
```

### 典型场景（Level 2）

```gdscript
# UI 层订阅多个事件
extends CanvasLayer

var _events: EventService = null


func _ready() -> void:
    _events = ServiceRegistry.get_service("events") as EventService
    if _events == null:
        push_error("EventService not available")
        return
    _events.damage_applied.connect(_on_damage_applied)
    _events.entity_died.connect(_on_entity_died)
    _events.quest_completed.connect(_on_quest_completed)


func _on_damage_applied(result: DamageResult) -> void:
    # 显示浮动伤害数字
    _spawn_damage_number(result.final_amount, result.target)


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
    if entity_id == "player":
        _show_game_over_screen()
    else:
        _play_enemy_death_vfx(entity_ref)


func _on_quest_completed(quest_id: String) -> void:
    _show_quest_complete_banner(quest_id)


# 调试：检查最近事件列表
func _debug_recent_events() -> void:
    var events := ServiceRegistry.get_service("events") as EventService
    if events == null:
        return
    for ev in events.recent_events:
        print("[%s] source=%s target=%s" % [ev.event_type, ev.source_id, ev.target_id])
```

## 相关

- → [DomainEvent](DomainEvent.md) — 事件对象结构
- → [pipeline.md — Event Notification](../../pipeline.md#8-event-notification)
- → [debugging.md](../../debugging.md) — recent_events 回放调试
- → [concepts.md — 模型 1：标准管线](../../concepts.md#模型-1标准管线时序图)（最后一跳）
