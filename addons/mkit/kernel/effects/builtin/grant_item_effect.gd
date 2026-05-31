class_name GrantItemEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `item_id`.
## Example: `self.item_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var item_id: String = ""
## Purpose: Inspector-exposed configuration `quantity`.
## Example: `self.quantity = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var quantity: int = 1
## Purpose: Inspector-exposed configuration `give_to_source`.
## Example: `self.give_to_source = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var give_to_source: bool = true


func _apply_impl(context: GameplayContext) -> EffectResult:
	if item_id == "":
		return EffectResult.fail(effect_id, "Missing item_id")

	var receiver := context.source if give_to_source else context.target
	if receiver == null:
		return EffectResult.fail(effect_id, "Missing receiver")

	var inventory := receiver.get_node_or_null("Controllers/InventoryController") as InventoryController
	if inventory == null:
		return EffectResult.fail(effect_id, "Receiver has no InventoryController")

	var item := ItemInstance.create(item_id, quantity)
	if not inventory.can_add_item(item):
		return EffectResult.fail(effect_id, "Inventory cannot accept item: %s" % item_id)

	inventory.add_item(item)
	return EffectResult.ok(effect_id, {
		"item_id": item_id,
		"quantity": quantity,
		"instance_id": item.instance_id
	})
