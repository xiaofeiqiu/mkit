class_name IAPService
extends Node
signal products_loaded(product_ids: Array)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(restored_ids: Array)


func load_products(product_ids: Array[String]) -> void:
	pass


func purchase(product_id: String) -> void:
	purchase_failed.emit(product_id, "not_implemented")


func restore_purchases() -> void:
	restore_completed.emit([])


func is_purchased(product_id: String) -> bool:
	return false
