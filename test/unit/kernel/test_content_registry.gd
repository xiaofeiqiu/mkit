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


class _QuestRes:
	extends Resource
	@export var quest_id: String = ""


class _DialogueRes:
	extends Resource
	@export var dialogue_id: String = ""


class _ShopRes:
	extends Resource
	@export var shop_id: String = ""


class _ZoneRes:
	extends Resource
	@export var zone_id: String = ""


class _ItemRes:
	extends Resource
	@export var item_id: String = ""
