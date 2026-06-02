extends GutTest


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


func _make_item_def(id: String, stackable: bool = false, max_stack: int = 1) -> ItemDefinition:
	var def := ItemDefinition.new()
	def.item_id = id
	def.stackable = stackable
	def.max_stack = max_stack
	return def


var inv: InventoryController
var content: StubContent
var entity: Node


func before_each() -> void:
	content = StubContent.new()
	ServiceRegistry.register_service("content", content)
	entity = Node.new()
	add_child_autofree(entity)
	inv = InventoryController.new()
	inv.capacity = 5
	entity.add_child(inv)
	inv._ready()


func after_each() -> void:
	ServiceRegistry.clear()


# --- add_item (non-stackable) ---


func test_tc_inv_01_add_item_returns_true_and_emits() -> void:
	content._defs["sword"] = _make_item_def("sword")
	var item := ItemInstance.create("sword", 1)
	watch_signals(inv)
	var result := inv.add_item(item)
	assert_true(result)
	assert_signal_emitted(inv, "item_added")
	assert_signal_emitted(inv, "inventory_changed")


func test_tc_inv_02_added_item_findable_by_instance_id() -> void:
	content._defs["sword"] = _make_item_def("sword")
	var item := ItemInstance.create("sword", 1)
	inv.add_item(item)
	var found := inv.find_item(item.instance_id)
	assert_not_null(found)
	assert_eq(found.definition_id, "sword")


func test_tc_inv_03_add_item_false_when_full() -> void:
	content._defs["coin"] = _make_item_def("coin")
	for i in inv.capacity:
		inv.add_item(ItemInstance.create("coin", 1))
	var result := inv.add_item(ItemInstance.create("coin", 1))
	assert_false(result)


func test_tc_inv_04_add_item_null_returns_false() -> void:
	var result := inv.add_item(null)
	assert_false(result)


func test_tc_inv_05_add_item_zero_quantity_returns_false() -> void:
	content._defs["sword"] = _make_item_def("sword")
	var item := ItemInstance.create("sword", 0)
	var result := inv.add_item(item)
	assert_false(result)


func test_tc_inv_06_add_item_missing_def_returns_false() -> void:
	var item := ItemInstance.create("undefined_item", 1)
	var result := inv.add_item(item)
	assert_false(result)


# --- add_item (stackable) ---


func test_tc_inv_07_stackable_item_stacks_into_existing_slot() -> void:
	content._defs["potion"] = _make_item_def("potion", true, 10)
	inv.add_item(ItemInstance.create("potion", 3))
	inv.add_item(ItemInstance.create("potion", 4))
	var found := inv.find_item_by_definition("potion")
	assert_eq(found.quantity, 7)


func test_tc_inv_08_stackable_overflows_to_new_slot() -> void:
	content._defs["arrow"] = _make_item_def("arrow", true, 5)
	inv.add_item(ItemInstance.create("arrow", 5))
	inv.add_item(ItemInstance.create("arrow", 3))
	var count := 0
	for slot in inv.model.slots:
		if slot.item != null and slot.item.definition_id == "arrow":
			count += slot.item.quantity
	assert_eq(count, 8)


# --- remove_item_by_instance_id ---


func test_tc_inv_09_remove_full_quantity_emits_item_removed() -> void:
	content._defs["potion"] = _make_item_def("potion", true, 10)
	var item := ItemInstance.create("potion", 3)
	inv.add_item(item)
	var found := inv.find_item_by_definition("potion")
	watch_signals(inv)
	inv.remove_item_by_instance_id(found.instance_id, 3)
	assert_signal_emitted(inv, "item_removed")
	assert_null(inv.find_item_by_definition("potion"))


func test_tc_inv_10_remove_partial_quantity_does_not_emit_item_removed() -> void:
	content._defs["potion"] = _make_item_def("potion", true, 10)
	inv.add_item(ItemInstance.create("potion", 5))
	var found := inv.find_item_by_definition("potion")
	watch_signals(inv)
	inv.remove_item_by_instance_id(found.instance_id, 2)
	assert_signal_not_emitted(inv, "item_removed")
	assert_eq(inv.find_item_by_definition("potion").quantity, 3)


func test_tc_inv_11_remove_missing_instance_returns_false() -> void:
	var result := inv.remove_item_by_instance_id("nonexistent_id")
	assert_false(result)


func test_tc_inv_12_remove_zero_quantity_returns_false() -> void:
	content._defs["sword"] = _make_item_def("sword")
	inv.add_item(ItemInstance.create("sword", 1))
	var found := inv.find_item_by_definition("sword")
	var result := inv.remove_item_by_instance_id(found.instance_id, 0)
	assert_false(result)


# --- find_item / find_item_by_definition ---


func test_tc_inv_13_find_item_null_for_unknown_id() -> void:
	assert_null(inv.find_item("bad_id"))


func test_tc_inv_14_find_item_by_def_null_when_not_present() -> void:
	assert_null(inv.find_item_by_definition("shield"))


# --- save / load ---


func test_tc_inv_15_save_load_roundtrip_preserves_items() -> void:
	content._defs["key"] = _make_item_def("key")
	inv.add_item(ItemInstance.create("key", 1))
	var data := inv.to_save_data()
	var inv2 := InventoryController.new()
	inv2.from_save_data(data)
	var has_key := inv2.model.slots.any(
		func(s): return s.item != null and s.item.definition_id == "key"
	)
	assert_true(has_key)
	inv2.free()


func test_tc_inv_16_from_save_data_empty_produces_empty_inventory() -> void:
	var items: Array = []
	for i in 5:
		items.append(null)
	inv.from_save_data({"capacity": 5, "items": items})
	for slot in inv.model.slots:
		assert_null(slot.item)


# --- has_item / get_item_count (via find_item_by_definition) ---


func test_tc_inv_17_find_by_def_not_null_when_item_present() -> void:
	content._defs["shield"] = _make_item_def("shield")
	inv.add_item(ItemInstance.create("shield", 1))
	assert_not_null(inv.find_item_by_definition("shield"))


func test_tc_inv_18_find_by_def_null_when_not_present() -> void:
	assert_null(inv.find_item_by_definition("axe"))


func test_tc_inv_19_total_quantity_counted_across_slots() -> void:
	content._defs["arrow"] = _make_item_def("arrow", true, 5)
	inv.add_item(ItemInstance.create("arrow", 4))
	inv.add_item(ItemInstance.create("arrow", 3))
	var total := 0
	for slot in inv.model.slots:
		if slot.item != null and slot.item.definition_id == "arrow":
			total += slot.item.quantity
	assert_eq(total, 7)


func test_tc_inv_20_count_zero_for_absent_definition() -> void:
	var total := 0
	for slot in inv.model.slots:
		if slot.item != null and slot.item.definition_id == "nonexistent":
			total += slot.item.quantity
	assert_eq(total, 0)


# --- EventRouter integration ---


func test_tc_inv_21_add_item_triggers_inventory_changed_event() -> void:
	var events := EventRouter.new()
	add_child_autofree(events)
	ServiceRegistry.register_service("events", events)
	content._defs["key"] = _make_item_def("key")
	watch_signals(events)
	inv.add_item(ItemInstance.create("key", 1))
	assert_signal_emitted(events, "inventory_changed")
