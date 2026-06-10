# WorldEvents

**层：** Modules（world）  
**文件：** `addons/mkit/modules/world/world_events.gd`  
**继承：** `extends RefCounted`

## 职责

world 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `ROOM_CLEARED` | `"room_cleared"` |
| `ZONE_CHANGED` | `"zone_changed"` |
| `RUN_STARTED` | `"run_started"` |
| `RUN_FINISHED` | `"run_finished"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `room_cleared(room_id: String) -> DomainEvent` | source 为 room_id |
| `zone_changed(from_zone_id, to_zone_id) -> DomainEvent` | payload 含 `from_zone_id` / `to_zone_id` |
| `run_started(run_id: String, seed: int) -> DomainEvent` | payload 含 `seed` |
| `run_finished(run_id: String, result: String) -> DomainEvent` | payload 含 `result`（如 `"completed"`、`"failed:player_died"`）|

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [RoomController](RoomController.md) / [RunDirector](RunDirector.md) / [WorldService](WorldService.md) — 发射方
