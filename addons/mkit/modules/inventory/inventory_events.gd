class_name InventoryEvents
extends RefCounted
## 背包领域事件目录：集中提供事件类型常量和 DomainEvent 构造方法。

## 稳定标识 `INVENTORY_CHANGED`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const INVENTORY_CHANGED := "inventory_changed"


## 执行 `inventory_changed` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
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
