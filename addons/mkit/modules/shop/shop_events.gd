class_name ShopEvents
extends RefCounted
## 商店领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `ITEM_PURCHASED`，作为 `ShopEvents` 对外暴露的类型、事件或命令标识。
const ITEM_PURCHASED := "item_purchased"
## 公开常量 `ITEM_SOLD`，作为 `ShopEvents` 对外暴露的类型、事件或命令标识。
const ITEM_SOLD := "item_sold"


## 执行 `item_purchased` 对应的公开操作，并保持 `ShopEvents` 的领域契约一致。
static func item_purchased(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_PURCHASED, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)


## 执行 `item_sold` 对应的公开操作，并保持 `ShopEvents` 的领域契约一致。
static func item_sold(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_SOLD, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)
