# InventoryEvents

**层：** Modules（inventory）  
**文件：** `addons/mkit/modules/inventory/inventory_events.gd`  
**继承：** `extends RefCounted`

## 职责

inventory 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `INVENTORY_CHANGED` | `"inventory_changed"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `inventory_changed(owner_id, item_id = "", quantity = 0, change_type = "") -> DomainEvent` | payload 必含 `owner_id`；`item_id` / `quantity` / `change_type` 非空时附带。`change_type` 取值：`"added"` / `"removed"` / `"loaded"` |

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [InventoryController](InventoryController.md) — 发射方
- → [QuestService](QuestService.md) — 订阅方（采集目标按此事件推进）
