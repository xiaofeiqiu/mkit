class_name ShopEvents
extends RefCounted
## 商店领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `ITEM_PURCHASED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ITEM_PURCHASED := "item_purchased"
## 稳定标识 `ITEM_SOLD`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ITEM_SOLD := "item_sold"


## 执行 `item_purchased` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func item_purchased(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_PURCHASED, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)


## 执行 `item_sold` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
static func item_sold(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_SOLD, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)
