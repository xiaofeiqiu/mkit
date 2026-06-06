extends GutTest

var registry: ContentRegistry


func before_each() -> void:
	registry = ContentRegistry.new()
	add_child_autofree(registry)


# --- new rpg content ids resolve through _extract_content_id ---


func test_tc_cr_01_registers_and_gets_by_quest_id() -> void:
	var res := _QuestRes.new()
	res.quest_id = "quest.gather_herbs"
	registry.register_resource(res)
	assert_true(registry.has("quest.gather_herbs"))
	assert_eq(registry.get_resource("quest.gather_herbs"), res)


func test_tc_cr_02_registers_and_gets_by_dialogue_id() -> void:
	var res := _DialogueRes.new()
	res.dialogue_id = "dlg.elder"
	registry.register_resource(res)
	assert_eq(registry.get_resource("dlg.elder"), res)


func test_tc_cr_03_registers_and_gets_by_shop_id() -> void:
	var res := _ShopRes.new()
	res.shop_id = "shop.village"
	registry.register_resource(res)
	assert_eq(registry.get_resource("shop.village"), res)


func test_tc_cr_04_registers_and_gets_by_zone_id() -> void:
	var res := _ZoneRes.new()
	res.zone_id = "zone.field"
	registry.register_resource(res)
	assert_eq(registry.get_resource("zone.field"), res)


func test_tc_cr_05_existing_item_id_still_resolves() -> void:
	var res := _ItemRes.new()
	res.item_id = "item.potion"
	registry.register_resource(res)
	assert_eq(registry.get_resource("item.potion"), res)


func test_tc_cr_06_unregistered_id_returns_null() -> void:
	assert_null(registry.get_resource("quest.missing"))
	assert_false(registry.has("quest.missing"))


func test_tc_cr_07_get_typed_resource_returns_resource_on_type_match() -> void:
	var res := _ItemRes.new()
	res.item_id = "item.sword"
	registry.register_resource(res)
	var result := registry.get_typed_resource("item.sword", _ItemRes as Script)
	assert_eq(result, res)


func test_tc_cr_08_get_typed_resource_returns_null_on_type_mismatch() -> void:
	var res := _ItemRes.new()
	res.item_id = "item.shield"
	registry.register_resource(res)
	var result := registry.get_typed_resource("item.shield", _QuestRes as Script)
	assert_null(result)
	assert_push_error("item.shield")


class _QuestRes:
	extends ContentDefinition
	@export var quest_id: String = ""
	func get_content_id() -> String: return quest_id


class _DialogueRes:
	extends ContentDefinition
	@export var dialogue_id: String = ""
	func get_content_id() -> String: return dialogue_id


class _ShopRes:
	extends ContentDefinition
	@export var shop_id: String = ""
	func get_content_id() -> String: return shop_id


class _ZoneRes:
	extends ContentDefinition
	@export var zone_id: String = ""
	func get_content_id() -> String: return zone_id


class _ItemRes:
	extends ContentDefinition
	@export var item_id: String = ""
	func get_content_id() -> String: return item_id
