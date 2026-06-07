class_name GrantItemEffect
extends GameEffect
@export var item_id: String = ""
@export var quantity: int = 1
@export var give_to_source: bool = true


func _apply_impl(context: GameplayContext) -> EffectResult:
	if item_id == "":
		return EffectResult.fail(effect_id, "Missing item_id")
	var receiver := context.source if give_to_source else context.target
	if receiver == null:
		return EffectResult.fail(effect_id, "Missing receiver")
	var inventory := (
		EntityContract.get_controller(receiver, "InventoryController") as InventoryController
	)
	if inventory == null:
		return EffectResult.fail(effect_id, "Receiver has no InventoryController")
	var item := ItemInstance.create(item_id, quantity)
	if not inventory.can_add_item(item):
		return EffectResult.fail(effect_id, "Inventory cannot accept item: %s" % item_id)
	inventory.add_item(item)
	return EffectResult.ok(
		effect_id, {"item_id": item_id, "quantity": quantity, "instance_id": item.instance_id}
	)
