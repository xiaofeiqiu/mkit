class_name LootSystem
extends RefCounted


func roll_table(table_id: String, context: GameplayContext) -> LootRollResult:
	var content := ServiceRegistry.get_service("content") as ContentRegistry
	var table := content.get_resource(table_id) as LootTableDefinition
	if table == null:
		return LootRollResult.new()
	return roll(table, context)


func roll(table: LootTableDefinition, context: GameplayContext) -> LootRollResult:
	var result := LootRollResult.new()
	var random := ServiceRegistry.get_service("random") as RandomService

	for _i in range(table.rolls):
		var candidates := _get_valid_entries(table, context)
		var total_weight := table.empty_weight if table.allow_empty else 0.0
		for entry in candidates:
			total_weight += entry.weight

		if total_weight <= 0:
			continue

		var r := random.randf_range(0.0, total_weight) if random != null else randf_range(0.0, total_weight)
		if table.allow_empty and r < table.empty_weight:
			result.debug_rolls.append({"roll": r, "result": "empty"})
			continue

		var cursor := table.empty_weight if table.allow_empty else 0.0
		for entry in candidates:
			cursor += entry.weight
			if r <= cursor:
				var quantity := _roll_quantity(entry, random)
				result.item_instances.append(ItemInstance.create(entry.content_id, quantity))
				result.debug_rolls.append({"roll": r, "result": entry.content_id, "quantity": quantity})
				break

	return result


func _get_valid_entries(table: LootTableDefinition, context: GameplayContext) -> Array[LootEntry]:
	var result: Array[LootEntry] = []
	for entry in table.entries:
		if ConditionEvaluator.evaluate_all(entry.conditions, context):
			result.append(entry)
	return result


func _roll_quantity(entry: LootEntry, random: RandomService) -> int:
	if entry.min_quantity >= entry.max_quantity:
		return entry.min_quantity
	if random != null:
		return random.randi_range(entry.min_quantity, entry.max_quantity)
	return randi_range(entry.min_quantity, entry.max_quantity)
