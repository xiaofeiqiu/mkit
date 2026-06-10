class_name ShopEvents
extends RefCounted
## Shop-owned domain event catalog: event type constants + DomainEvent constructors.

const ITEM_PURCHASED := "item_purchased"
const ITEM_SOLD := "item_sold"


static func item_purchased(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_PURCHASED, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)


static func item_sold(shop_id: String, item_id: String, quantity: int) -> DomainEvent:
	return DomainEvent.create(
		ITEM_SOLD, shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
	)
