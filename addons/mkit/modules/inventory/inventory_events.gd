class_name InventoryEvents
extends RefCounted
## 背包领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 公开常量 `INVENTORY_CHANGED`，作为 `InventoryEvents` 对外暴露的类型、事件或命令标识。
const INVENTORY_CHANGED := "inventory_changed"


## 执行 `inventory_changed` 对应的公开操作，并保持 `InventoryEvents` 的领域契约一致。
static func inventory_changed(
	owner_id: String, item_id: String = "", quantity: int = 0, change_type: String = ""
) -> DomainEvent:
	var payload: Dictionary = {"owner_id": owner_id}
	if item_id != "":
		payload["item_id"] = item_id
	if quantity > 0:
		payload["quantity"] = quantity
	if change_type != "":
		payload["change_type"] = change_type
	return DomainEvent.create(INVENTORY_CHANGED, owner_id, item_id, payload)
