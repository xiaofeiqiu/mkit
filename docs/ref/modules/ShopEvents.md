# ShopEvents

**层：** Modules（shop）  
**文件：** `addons/mkit/modules/shop/shop_events.gd`  
**继承：** `extends RefCounted`

## 职责

shop 模块的领域事件目录：事件类型常量 + `DomainEvent` 构造函数。

## 常量

| 常量 | 值 |
|------|-----|
| `ITEM_PURCHASED` | `"item_purchased"` |
| `ITEM_SOLD` | `"item_sold"` |

## 方法（static）

| 方法签名 | 说明 |
|----------|------|
| `item_purchased(shop_id, item_id, quantity) -> DomainEvent` | source 为 shop_id，target 为 item_id，payload 含三者 |
| `item_sold(shop_id, item_id, quantity) -> DomainEvent` | 同上 |

## 相关

- → [EventService](../kernel/EventService.md) / [DomainEvent](../kernel/DomainEvent.md)
- → [ShopService](ShopService.md) — 发射方；其类型化信号依旧保留
