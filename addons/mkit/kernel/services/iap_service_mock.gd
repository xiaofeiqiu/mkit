class_name IAPServiceMock
extends IAPService
var _purchased: Array[String] = []


func load_products(product_ids: Array[String]) -> void:
	await get_tree().create_timer(0.1).timeout
	products_loaded.emit(product_ids)


func purchase(product_id: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if not _purchased.has(product_id):
		_purchased.append(product_id)
	purchase_completed.emit(product_id)
	print("[IAP] purchase_completed: %s" % product_id)


func restore_purchases() -> void:
	await get_tree().create_timer(0.2).timeout
	restore_completed.emit(_purchased.duplicate())
	print("[IAP] restore_completed: %s" % str(_purchased))


func is_purchased(product_id: String) -> bool:
	return _purchased.has(product_id)
