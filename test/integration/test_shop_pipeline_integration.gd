extends GutTest


const SAVE_PATH := "/tmp/mkit_shop_pipeline_integration_save.json"


func after_each() -> void:
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_shop_01_open_buy_sell_and_stock_pipeline() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)

	var shop := ServiceRegistry.get_service("shop") as ShopService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	var events := ServiceRegistry.get_service("events") as EventService
	assert_not_null(shop)
	assert_not_null(progression)
	assert_not_null(events)

	var buyer := _make_buyer()
	var inventory := buyer.get_node("Controllers/InventoryController") as InventoryController

	watch_signals(shop)
	watch_signals(events)
	watch_signals(progression)

	assert_true(shop.open_shop("shop.int.village"))
	assert_signal_emitted_with_parameters(shop, "shop_opened", ["shop.int.village"])
	assert_eq(shop.get_buy_price("item.int.potion"), 10)

	assert_false(shop.buy("item.int.potion", 2, buyer))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.int.potion", "Insufficient currency"]
	)
	assert_eq(progression.get_currency("gold"), 0)

	progression.add_currency("gold", 100)
	assert_true(shop.buy("item.int.potion", 2, buyer))
	assert_eq(progression.get_currency("gold"), 80)
	var potion := inventory.find_item_by_definition("item.int.potion")
	assert_not_null(potion)
	assert_eq(potion.quantity, 2)
	var evt_item_purchased_4 := DomainEventAsserts.last_event(events, "item_purchased")
	assert_not_null(evt_item_purchased_4)
	assert_eq(evt_item_purchased_4.source_id, "shop.int.village")
	assert_eq(evt_item_purchased_4.target_id, "item.int.potion")
	assert_eq(evt_item_purchased_4.payload.get("quantity"), 2)

	assert_true(shop.sell(potion.instance_id, 1, buyer))
	assert_eq(inventory.find_item_by_definition("item.int.potion").quantity, 1)
	assert_eq(progression.get_currency("gold"), 85)
	var evt_item_sold_5 := DomainEventAsserts.last_event(events, "item_sold")
	assert_not_null(evt_item_sold_5)
	assert_eq(evt_item_sold_5.source_id, "shop.int.village")
	assert_eq(evt_item_sold_5.target_id, "item.int.potion")
	assert_eq(evt_item_sold_5.payload.get("quantity"), 1)

	assert_true(shop.buy("item.int.limited", 1, buyer))
	assert_false(shop.buy("item.int.limited", 1, buyer))
	assert_signal_emitted_with_parameters(
		shop, "transaction_failed", ["item.int.limited", "Out of stock"]
	)


func _make_database() -> ResourceDatabase:
	var potion := IntTestHelpers.make_item_definition("item.int.potion", true, 99, 10)
	var limited := IntTestHelpers.make_item_definition("item.int.limited", true, 99, 5)

	var potion_entry := ShopEntry.new()
	potion_entry.item_id = "item.int.potion"

	var limited_entry := ShopEntry.new()
	limited_entry.item_id = "item.int.limited"
	limited_entry.stock = 1

	var entries: Array[ShopEntry] = [potion_entry, limited_entry]
	var shop := ShopDefinition.new()
	shop.shop_id = "shop.int.village"
	shop.display_name = "Village Supply"
	shop.currency_id = "gold"
	shop.entries = entries
	shop.buy_price_multiplier = 1.0
	shop.sell_price_multiplier = 0.5
	shop.allow_sell = true

	var resources: Array[Resource] = [potion, limited, shop]
	return IntTestHelpers.make_resource_database("shop_int", resources)


func _make_buyer() -> Node:
	var buyer := IntTestHelpers.make_inventory_entity("Buyer", "buyer", 10)
	add_child_autofree(buyer)
	return buyer
