extends GutTest

var reg: Node


func before_each() -> void:
	reg = load("res://addons/mkit/kernel/services/service_registry.gd").new()


func after_each() -> void:
	reg.free()


# --- register_service ---


func test_tc_sr_01_register_and_retrieve() -> void:
	var obj := Node.new()
	assert_true(reg.register_service("foo", obj))
	assert_true(reg.has_service("foo"))
	assert_eq(reg.get_port("foo"), obj)
	obj.free()


func test_tc_sr_02_empty_id_is_noop() -> void:
	var obj := Node.new()
	assert_false(reg.register_service("", obj))
	assert_push_error("service_id is empty")
	assert_false(reg.has_service(""))
	obj.free()


func test_tc_sr_03_null_service_is_noop() -> void:
	assert_false(reg.register_service("bar", null))
	assert_push_error("service is null")
	assert_false(reg.has_service("bar"))


func test_tc_sr_04_duplicate_id_is_rejected() -> void:
	var obj1 := Node.new()
	var obj2 := Node.new()
	assert_true(reg.register_service("dup", obj1))
	assert_false(reg.register_service("dup", obj2))
	assert_push_error("Service already registered")
	assert_eq(reg.get_port("dup"), obj1)
	obj1.free()
	obj2.free()


func test_tc_sr_05_replace_service_replaces_existing() -> void:
	var obj1 := Node.new()
	var obj2 := Node.new()
	assert_true(reg.register_service("replace_me", obj1))
	assert_true(reg.replace_service("replace_me", obj2))
	assert_eq(reg.get_port("replace_me"), obj2)
	obj1.free()
	obj2.free()


func test_tc_sr_06_replace_service_rejects_missing_id() -> void:
	var obj := Node.new()
	assert_false(reg.replace_service("missing", obj))
	assert_push_error("missing service id")
	assert_false(reg.has_service("missing"))
	obj.free()


# --- has_service ---


func test_tc_sr_07_has_service_false_for_missing() -> void:
	assert_false(reg.has_service("not_there"))


func test_tc_sr_08_has_service_false_for_whitespace() -> void:
	assert_false(reg.has_service("   "))


# --- get_port ---


func test_tc_sr_09_get_port_null_for_missing() -> void:
	assert_null(reg.get_port("missing"))


func test_tc_sr_10_get_port_null_for_empty() -> void:
	assert_null(reg.get_port(""))


# --- unregister_service ---


func test_tc_sr_11_unregister_removes_service() -> void:
	var obj := Node.new()
	assert_true(reg.register_service("x", obj))
	reg.unregister_service("x")
	assert_false(reg.has_service("x"))
	obj.free()


func test_tc_sr_12_unregister_missing_is_safe() -> void:
	var obj := Node.new()
	assert_true(reg.register_service("kept", obj))
	reg.unregister_service("does_not_exist")
	assert_true(reg.has_service("kept"))
	assert_eq(reg.get_port("kept"), obj)
	assert_eq(reg.get_registered_service_ids(), ["kept"])
	obj.free()


# --- clear ---


func test_tc_sr_13_unregister_strips_edges() -> void:
	var obj := Node.new()
	assert_true(reg.register_service("trimmed", obj))
	reg.unregister_service("  trimmed  ")
	assert_false(reg.has_service("trimmed"))
	obj.free()


func test_tc_sr_14_clear_removes_all() -> void:
	var a := Node.new()
	var b := Node.new()
	assert_true(reg.register_service("a", a))
	assert_true(reg.register_service("b", b))
	reg.clear()
	assert_false(reg.has_service("a"))
	assert_false(reg.has_service("b"))
	a.free()
	b.free()


func test_tc_sr_15_registered_service_ids_are_sorted() -> void:
	var z := Node.new()
	var a := Node.new()
	assert_true(reg.register_service("zeta", z))
	assert_true(reg.register_service("alpha", a))
	assert_eq(reg.get_registered_service_ids(), ["alpha", "zeta"])
	z.free()
	a.free()
