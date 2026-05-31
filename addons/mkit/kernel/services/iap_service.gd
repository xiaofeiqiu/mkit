## What: IAPService is the platform abstraction for in-app purchases and purchase restoration.
## Responsibilities: load products, purchase product ids, restore purchases, check ownership, and emit purchase signals.
## Upstream: shop UI, progression unlocks, or monetization flows call it through ServiceRegistry.
## Downstream: App Store, Google Play, Steam, or mock adapters fulfill purchases and restoration.
## When to use: Use it when game code needs purchases without directly importing store SDK APIs.
## Example: `iap.load_products(["starter_pack"]); iap.purchase("starter_pack")`.
class_name IAPService
extends Node

## In-app purchase platform abstraction. Monetisation flows depend on this interface only.

## Purpose: Emits the `products_loaded` signal so external listeners can react to this runtime event.
## Example: `self.products_loaded.connect(_on_products_loaded)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal products_loaded(product_ids: Array)
## Purpose: Emits the `purchase_completed` signal so external listeners can react to this runtime event.
## Example: `self.purchase_completed.connect(_on_purchase_completed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal purchase_completed(product_id: String)
## Purpose: Emits the `purchase_failed` signal so external listeners can react to this runtime event.
## Example: `self.purchase_failed.connect(_on_purchase_failed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal purchase_failed(product_id: String, reason: String)
## Purpose: Emits the `restore_completed` signal so external listeners can react to this runtime event.
## Example: `self.restore_completed.connect(_on_restore_completed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal restore_completed(restored_ids: Array)


## Purpose: Public method `load_products` used by external systems to invoke this class behavior.
## Example: `self.load_products(["starter_pack"])`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func load_products(product_ids: Array[String]) -> void:
	pass


## Purpose: Public method `purchase` used by external systems to invoke this class behavior.
## Example: `self.purchase("product_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func purchase(product_id: String) -> void:
	purchase_failed.emit(product_id, "not_implemented")


## Purpose: Public method `restore_purchases` used by external systems to invoke this class behavior.
## Example: `self.restore_purchases()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func restore_purchases() -> void:
	restore_completed.emit([])


## Purpose: Public method `is_purchased` used by external systems to invoke this class behavior.
## Example: `self.is_purchased("product_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_purchased(product_id: String) -> bool:
	return false
