## What: IAPServiceMock is the development implementation of IAPService for local purchase testing.
## Responsibilities: simulate product loading, instant purchases, restore purchased ids, and ownership checks.
## Upstream: GameBootstrap or tests register it for editor/demo builds.
## Downstream: shop UI and unlock flows receive normal purchase_completed/restore_completed signals.
## When to use: Use it for shop and entitlement development before integrating a real store backend.
## Example: `iap.purchase("starter_pack"); if iap.is_purchased("starter_pack"): unlock_starter_pack()`.
class_name IAPServiceMock
extends IAPService

## Development-time IAP: simulates instant purchases without a real store backend.

var _purchased: Array[String] = []


## Purpose: Public method `load_products` used by external systems to invoke this class behavior.
## Example: `self.load_products(["starter_pack"])`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func load_products(product_ids: Array[String]) -> void:
	await get_tree().create_timer(0.1).timeout
	products_loaded.emit(product_ids)


## Purpose: Public method `purchase` used by external systems to invoke this class behavior.
## Example: `self.purchase("product_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func purchase(product_id: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if not _purchased.has(product_id):
		_purchased.append(product_id)
	purchase_completed.emit(product_id)
	print("[IAP] purchase_completed: %s" % product_id)


## Purpose: Public method `restore_purchases` used by external systems to invoke this class behavior.
## Example: `self.restore_purchases()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func restore_purchases() -> void:
	await get_tree().create_timer(0.2).timeout
	restore_completed.emit(_purchased.duplicate())
	print("[IAP] restore_completed: %s" % str(_purchased))


## Purpose: Public method `is_purchased` used by external systems to invoke this class behavior.
## Example: `self.is_purchased("product_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_purchased(product_id: String) -> bool:
	return _purchased.has(product_id)
