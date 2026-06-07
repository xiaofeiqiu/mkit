extends GutTest

var reg: Node


func before_each() -> void:
	reg = load("res://addons/mkit/kernel/services/service_registry.gd").new()


func after_each() -> void:
	reg.free()


# --- register_service ---


func test_tc_sr_01_register_and_retrieve() -> void:
	var obj := Node.new()
	reg.register_service("foo", obj)
	assert_true(reg.has_service("foo"))
	assert_eq(reg.get_service("foo"), obj)
	obj.free()


func test_tc_sr_02_empty_id_is_noop() -> void:
	var obj := Node.new()
	reg.register_service("", obj)
	assert_false(reg.has_service(""))
	obj.free()


func test_tc_sr_03_null_service_is_noop() -> void:
	reg.register_service("bar", null)
	assert_false(reg.has_service("bar"))


func test_tc_sr_04_duplicate_id_replaces() -> void:
	var obj1 := Node.new()
	var obj2 := Node.new()
	reg.register_service("dup", obj1)
	reg.register_service("dup", obj2)
	assert_eq(reg.get_service("dup"), obj2)
	obj1.free()
	obj2.free()


# --- has_service ---


func test_tc_sr_05_has_service_false_for_missing() -> void:
	assert_false(reg.has_service("not_there"))


func test_tc_sr_06_has_service_false_for_whitespace() -> void:
	assert_false(reg.has_service("   "))


# --- get_service ---


func test_tc_sr_07_get_service_null_for_missing() -> void:
	assert_null(reg.get_service("missing"))


func test_tc_sr_08_get_service_null_for_empty() -> void:
	assert_null(reg.get_service(""))


# --- unregister_service ---


func test_tc_sr_09_unregister_removes_service() -> void:
	var obj := Node.new()
	reg.register_service("x", obj)
	reg.unregister_service("x")
	assert_false(reg.has_service("x"))
	obj.free()


func test_tc_sr_10_unregister_missing_is_safe() -> void:
	reg.unregister_service("does_not_exist")
	assert_true(true)


# --- clear ---


func test_tc_sr_11_clear_removes_all() -> void:
	var a := Node.new()
	var b := Node.new()
	reg.register_service("a", a)
	reg.register_service("b", b)
	reg.clear()
	assert_false(reg.has_service("a"))
	assert_false(reg.has_service("b"))
	a.free()
	b.free()


# --- get_typed ---


func test_tc_sr_12_get_typed_returns_object_on_match() -> void:
	var obj := EventService.new()
	reg.register_service("events", obj)
	var result: Object = reg.get_typed("events", "EventService")
	assert_eq(result, obj)
	obj.free()


func test_tc_sr_13_get_typed_returns_object_on_mismatch_with_warning() -> void:
	var obj := Node.new()
	reg.register_service("thing", obj)
	var result: Object = reg.get_typed("thing", "EventService")
	assert_eq(result, obj)
	obj.free()


func test_tc_sr_14_registered_service_ids_are_sorted() -> void:
	var z := Node.new()
	var a := Node.new()
	reg.register_service("zeta", z)
	reg.register_service("alpha", a)
	assert_eq(reg.get_registered_service_ids(), ["alpha", "zeta"])
	z.free()
	a.free()
