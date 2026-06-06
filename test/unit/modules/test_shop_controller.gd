extends GutTest


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class FailingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return false


var shop: ShopController
var content: StubContent
var events: EventRouter
var progression: ProgressionSystem


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventRouter.new()
	add_child_autofree(events)
	progression = ProgressionSystem.new()
	add_child_autofree(progression)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("progression", progression)
	shop = ShopController.new()
	add_child_autofree(shop)
	ServiceRegistry.register_service("shop", shop)


func after_each() -> void:
	ServiceRegistry.clear()


# --- helpers ---


func _make_item(
	id: String, value: int, stackable: bool = true, max_stack: int = 99
) -> ItemDefinition:
	var definition := ItemDefinition.new()
	definition.item_id = id
	definition.value = value
	definition.stackable = stackable
	definition.max_stack = max_stack
	content._defs[id] = definition
	return definition


func _make_entry(
	item_id: String, price_override: int = -1, stock: int = -1
) -> ShopEntry:
	var entry := ShopEntry.new()
	entry.item_id = item_id
	entry.price_override = price_override
	entry.stock = stock
	return entry


func _make_shop(
	id: String,
	entries: Array[ShopEntry],
	buy_mult: float = 1.0,
	sell_mult: float = 0.5,
	allow_sell: bool = true
) -> ShopDefinition:
	var definition := ShopDefinition.new()
	definition.shop_id = id
	definition.currency_id = "gold"
	definition.entries = entries
	definition.buy_price_multiplier = buy_mult
	definition.sell_price_multiplier = sell_mult
	definition.allow_sell = allow_sell
	content._defs[id] = definition
	return definition


func _make_buyer(capacity: int = 30) -> Node:
	var buyer := Node.new()
	buyer.name = "Buyer"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "buyer"
	buyer.add_child(identity)
	var controllers := Node.new()
	controllers.name = "Controllers"
	buyer.add_child(controllers)
	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = capacity
	controllers.add_child(inventory)
	add_child_autofree(buyer)
	return buyer


func _inventory_of(buyer: Node) -> InventoryController:
	return buyer.get_node("Controllers/InventoryController") as InventoryController


func _make_ui() -> ShopUI:
	var ui := ShopUI.new()
	var container := Control.new()
	container.name = "EntryContainer"
	ui.add_child(container)
	add_child_autofree(ui)
	return ui


# --- buy: spend currency + grant item + events ---


func test_tc_shop_01_buy_spends_currency_and_grants_item() -> void:
	_make_item("item.potion", 10)
	var entries: Array[ShopEntry] = [_make_entry("item.potion")]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer()

	assert_false(shop.open_shop("shop.missing"))
	watch_signals(shop)
	assert_true(shop.open_shop("shop.village"))
	assert_signal_emitted_with_parameters(shop, "shop_opened", ["shop.village"])
	assert_eq(shop.get_buy_price("item.potion"), 10)

	assert_false(shop.can_buy("item.potion", 2, buyer))

	progression.add_currency("gold", 100)
	assert_true(shop.can_buy("item.potion", 2, buyer))

	watch_signals(events)
	assert_true(shop.buy("item.potion", 2, buyer))
	assert_eq(progression.get_currency("gold"), 80)
	var item := _inventory_of(buyer).find_item_by_definition("item.potion")
	assert_not_null(item)
	assert_eq(item.quantity, 2)
	assert_signal_emitted_with_parameters(shop, "item_purchased", ["item.potion", 2, 20])
	assert_signal_emitted_with_parameters(
		events, "item_purchased", ["shop.village", "item.potion", 2]
	)


# --- buy: insufficient currency is rejected ---


func test_tc_shop_02_buy_fails_when_currency_insufficient() -> void:
	_make_item("item.potion", 10)
	var entries: Array[ShopEntry] = [_make_entry("item.potion")]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer()
	shop.open_shop("shop.village")
	progression.add_currency("gold", 5)

	watch_signals(shop)
	watch_signals(events)
	assert_false(shop.buy("item.potion", 1, buyer))
	assert_eq(progression.get_currency("gold"), 5)
	assert_null(_inventory_of(buyer).find_item_by_definition("item.potion"))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.potion", "Insufficient currency"]
	)
	assert_signal_not_emitted(shop, "item_purchased")
	assert_signal_not_emitted(events, "item_purchased")


# --- stock decrements, blocks at zero, conditions gate ---


func test_tc_shop_03_stock_decrements_and_blocks_when_zero() -> void:
	_make_item("item.elixir", 4)
	_make_item("item.locked", 4)
	var locked_entry := _make_entry("item.locked")
	var failing: Array[Condition] = [FailingCondition.new()]
	locked_entry.conditions = failing
	var entries: Array[ShopEntry] = [_make_entry("item.elixir", -1, 2), locked_entry]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer()
	shop.open_shop("shop.village")
	progression.add_currency("gold", 100)

	assert_true(shop.buy("item.elixir", 1, buyer))
	assert_eq(entries[0].stock, 1)
	assert_true(shop.buy("item.elixir", 1, buyer))
	assert_eq(entries[0].stock, 0)

	watch_signals(shop)
	assert_false(shop.can_buy("item.elixir", 1, buyer))
	assert_false(shop.buy("item.elixir", 1, buyer))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.elixir", "Out of stock"]
	)

	assert_false(shop.can_buy("item.locked", 1, buyer))
	assert_false(shop.buy("item.locked", 1, buyer))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.locked", "Entry locked"]
	)


# --- sell: remove item + add currency + reject paths ---


func test_tc_shop_04_sell_removes_item_and_adds_currency() -> void:
	_make_item("item.gem", 20)
	var entries: Array[ShopEntry] = [_make_entry("item.gem")]
	var definition := _make_shop("shop.village", entries, 1.0, 0.5, true)
	var seller := _make_buyer()
	shop.open_shop("shop.village")
	var inventory := _inventory_of(seller)
	inventory.add_item(ItemInstance.create("item.gem", 3))
	var instance_id := inventory.find_item_by_definition("item.gem").instance_id

	watch_signals(shop)
	watch_signals(events)
	assert_true(shop.sell(instance_id, 2, seller))
	assert_eq(inventory.find_item_by_definition("item.gem").quantity, 1)
	assert_eq(progression.get_currency("gold"), 20)
	assert_signal_emitted_with_parameters(shop, "item_sold", ["item.gem", 2, 20])
	assert_signal_emitted_with_parameters(events, "item_sold", ["shop.village", "item.gem", 2])

	assert_false(shop.sell("item.does_not_exist", 1, seller))

	definition.allow_sell = false
	assert_false(shop.sell(instance_id, 1, seller))
	assert_signal_emitted_with_parameters(shop, "transaction_failed", ["", "Shop does not buy items"])


# --- pricing: override + multipliers ---


func test_tc_shop_05_price_override_and_multipliers() -> void:
	_make_item("item.sword", 100)
	var entries: Array[ShopEntry] = [
		_make_entry("item.sword", 250), _make_entry("item.shield", -1)
	]
	_make_item("item.shield", 40)
	_make_shop("shop.smith", entries, 1.5, 0.25)

	assert_eq(shop.get_buy_price("item.sword"), -1)
	shop.open_shop("shop.smith")

	assert_eq(shop.get_buy_price("item.sword"), 250)
	assert_eq(shop.get_sell_price("item.sword"), 25)
	assert_eq(shop.get_buy_price("item.shield"), 60)
	assert_eq(shop.get_sell_price("item.shield"), 10)
	assert_eq(shop.get_buy_price("item.unknown"), -1)


# --- regression: zero-price entries are purchasable (can_buy == buy) ---


func test_tc_shop_06_zero_price_entry_is_purchasable() -> void:
	_make_item("item.free_override", 50)
	_make_item("item.free_default", 0)
	var entries: Array[ShopEntry] = [
		_make_entry("item.free_override", 0), _make_entry("item.free_default")
	]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer()
	shop.open_shop("shop.village")

	assert_eq(shop.get_buy_price("item.free_override"), 0)
	assert_eq(shop.get_buy_price("item.free_default"), 0)

	watch_signals(shop)
	assert_true(shop.can_buy("item.free_override", 1, buyer))
	assert_true(shop.buy("item.free_override", 1, buyer))
	assert_true(shop.can_buy("item.free_default", 3, buyer))
	assert_true(shop.buy("item.free_default", 3, buyer))

	assert_eq(progression.get_currency("gold"), 0)
	assert_eq(_inventory_of(buyer).find_item_by_definition("item.free_override").quantity, 1)
	assert_eq(_inventory_of(buyer).find_item_by_definition("item.free_default").quantity, 3)
	assert_signal_emitted_with_parameters(shop, "item_purchased", ["item.free_override", 1, 0], 0)
	assert_signal_emitted_with_parameters(shop, "item_purchased", ["item.free_default", 3, 0], 1)
	assert_signal_not_emitted(shop, "transaction_failed")


# --- regression: over-capacity buy is blocked, no debit, no partial grant ---


func test_tc_shop_07_over_capacity_buy_blocked_without_dupe() -> void:
	_make_item("item.relic", 10, false, 1)
	var entries: Array[ShopEntry] = [_make_entry("item.relic")]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer(3)
	shop.open_shop("shop.village")
	progression.add_currency("gold", 100)

	watch_signals(shop)
	assert_false(shop.can_buy("item.relic", 5, buyer))
	assert_false(shop.buy("item.relic", 5, buyer))
	assert_eq(progression.get_currency("gold"), 100)
	assert_null(_inventory_of(buyer).find_item_by_definition("item.relic"))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.relic", "Inventory cannot accept item"]
	)
	assert_signal_not_emitted(shop, "item_purchased")


# --- regression: ShopUI.bind wires the buyer so a button press purchases ---


func test_tc_shop_08_ui_bind_buyer_enables_purchase() -> void:
	_make_item("item.potion", 10)
	var entries: Array[ShopEntry] = [_make_entry("item.potion")]
	_make_shop("shop.village", entries)
	var buyer := _make_buyer()
	shop.open_shop("shop.village")
	progression.add_currency("gold", 50)

	var ui := _make_ui()
	ui.bind(shop, buyer)
	assert_eq(ui.buyer, buyer)
	var button := ui.get_node("EntryContainer").get_child(0) as Button
	assert_not_null(button)

	button.pressed.emit()
	var item := _inventory_of(buyer).find_item_by_definition("item.potion")
	assert_not_null(item)
	assert_eq(item.quantity, 1)
	assert_eq(progression.get_currency("gold"), 40)
