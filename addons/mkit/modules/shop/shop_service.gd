class_name ShopService
extends Node
## 说明：`ShopService` 是 商店系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(ShopService.SERVICE_ID, ShopService.new())`

## 当 `ShopService` 发生 `shop opened` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal shop_opened(shop_id: String)
## 当 `ShopService` 发生 `item purchased` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal item_purchased(item_id: String, quantity: int, total_cost: int)
## 当 `ShopService` 发生 `item sold` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal item_sold(item_id: String, quantity: int, total_gain: int)
## 当 `ShopService` 发生 `transaction failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal transaction_failed(item_id: String, reason: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `ShopService`。
const SERVICE_ID: String = "shop"
## 运行时状态：`current_shop` 表示当前值，由 `ShopService` 的公开 API 读取或维护。
var current_shop: ShopDefinition = null


## 打开对应 UI 或流程入口，并保持 `ShopService` 的领域契约一致。
func open_shop(shop_id: String) -> bool:
	var definition := get_definition(shop_id)
	if definition == null:
		return false
	current_shop = definition
	shop_opened.emit(shop_id)
	return true


## 关闭对应 UI 或流程入口，并保持 `ShopService` 的领域契约一致。
func close_shop() -> void:
	current_shop = null


## 返回 `buy_price` 对应的数据或对象，并保持 `ShopService` 的领域契约一致。
func get_buy_price(item_id: String) -> int:
	if current_shop == null:
		return -1
	var entry := current_shop.get_entry(item_id)
	if entry == null:
		return -1
	if entry.price_override >= 0:
		return entry.price_override
	var item_def := _get_item_definition(item_id)
	var base := item_def.value if item_def != null else 0
	return int(round(base * current_shop.buy_price_multiplier))


## 返回 `sell_price` 对应的数据或对象，并保持 `ShopService` 的领域契约一致。
func get_sell_price(item_id: String) -> int:
	if current_shop == null:
		return -1
	var item_def := _get_item_definition(item_id)
	if item_def == null:
		return -1
	return int(round(item_def.value * current_shop.sell_price_multiplier))


## 检查当前上下文是否允许 `buy`，并保持 `ShopService` 的领域契约一致。
func can_buy(item_id: String, quantity: int, buyer: Node) -> bool:
	return _buy_block_reason(item_id, quantity, buyer) == ""


## 执行 `buy` 对应的公开操作，并保持 `ShopService` 的领域契约一致。
func buy(item_id: String, quantity: int, buyer: Node) -> bool:
	var reason := _buy_block_reason(item_id, quantity, buyer)
	if reason != "":
		transaction_failed.emit(item_id, reason)
		return false
	var total_cost := get_buy_price(item_id) * quantity
	if total_cost > 0:
		var spend := SpendCurrencyEffect.new()
		spend.currency_id = current_shop.currency_id
		spend.amount = total_cost
		var result := _run_effect(spend, _make_context(buyer))
		if not result.success:
			transaction_failed.emit(item_id, "Insufficient currency")
			return false
	var inventory := _get_inventory(buyer)
	var item := ItemInstance.create(item_id, quantity)
	if not inventory.add_item(item):
		if total_cost > 0:
			var refund := AddCurrencyEffect.new()
			refund.currency_id = current_shop.currency_id
			refund.amount = total_cost
			_run_effect(refund, _make_context(buyer))
		transaction_failed.emit(item_id, "Inventory could not accept item")
		return false
	var entry := current_shop.get_entry(item_id)
	if entry != null and entry.stock >= 0:
		entry.stock = max(0, entry.stock - quantity)
	item_purchased.emit(item_id, quantity, total_cost)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(ShopEvents.item_purchased(current_shop.shop_id, item_id, quantity))
	return true


## 执行 `sell` 对应的公开操作，并保持 `ShopService` 的领域契约一致。
func sell(item_instance_id: String, quantity: int, seller: Node) -> bool:
	if current_shop == null:
		transaction_failed.emit("", "No shop open")
		return false
	if not current_shop.allow_sell:
		transaction_failed.emit("", "Shop does not buy items")
		return false
	if quantity <= 0:
		transaction_failed.emit("", "Invalid quantity")
		return false
	var inventory := _get_inventory(seller)
	if inventory == null:
		transaction_failed.emit("", "Seller has no inventory")
		return false
	var item := inventory.find_item(item_instance_id)
	if item == null:
		transaction_failed.emit("", "Item not in inventory")
		return false
	var item_id := item.definition_id
	if item.quantity < quantity:
		transaction_failed.emit(item_id, "Not enough quantity to sell")
		return false
	if _get_item_definition(item_id) == null:
		transaction_failed.emit(item_id, "Unknown item")
		return false
	var total_gain := get_sell_price(item_id) * quantity
	if not inventory.remove_item_by_instance_id(item_instance_id, quantity):
		transaction_failed.emit(item_id, "Could not remove item")
		return false
	var add := AddCurrencyEffect.new()
	add.currency_id = current_shop.currency_id
	add.amount = total_gain
	_run_effect(add, _make_context(seller))
	item_sold.emit(item_id, quantity, total_gain)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(ShopEvents.item_sold(current_shop.shop_id, item_id, quantity))
	return true


## 返回 `definition` 对应的数据或对象，并保持 `ShopService` 的领域契约一致。
func get_definition(shop_id: String) -> ShopDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(shop_id) as ShopDefinition


func _buy_block_reason(item_id: String, quantity: int, buyer: Node) -> String:
	if current_shop == null:
		return "No shop open"
	if quantity <= 0:
		return "Invalid quantity"
	var entry := current_shop.get_entry(item_id)
	if entry == null:
		return "Item not sold here"
	if _get_item_definition(item_id) == null:
		return "Unknown item"
	if not ConditionEvaluator.evaluate_all(entry.conditions, _make_context(buyer)):
		return "Entry locked"
	if entry.stock >= 0 and entry.stock < quantity:
		return "Out of stock"
	var inventory := _get_inventory(buyer)
	if inventory == null:
		return "Buyer has no inventory"
	if not inventory.can_add_item(ItemInstance.create(item_id, quantity)):
		return "Inventory cannot accept item"
	var total_cost := get_buy_price(item_id) * quantity
	if total_cost > 0 and not SpendCurrencyEffect.can_spend(current_shop.currency_id, total_cost):
		return "Insufficient currency"
	return ""


func _make_context(actor: Node) -> GameplayContext:
	return GameplayContext.from_nodes(actor, null)


func _run_effect(effect: GameEffect, ctx: GameplayContext) -> EffectResult:
	var effects := Mkit.effects()
	if effects != null:
		return effects.execute(effect, ctx)
	return effect.apply(ctx)


func _get_inventory(node: Node) -> InventoryController:
	if node == null:
		return null
	return EntityContract.get_controller(node, "InventoryController") as InventoryController


func _get_item_definition(item_id: String) -> ItemDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition
