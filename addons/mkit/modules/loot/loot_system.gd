class_name LootSystem
extends RefCounted


func roll_table(table_id: String, context: GameplayContext) -> LootRollResult:
	if table_id.strip_edges() == "":
		push_warning("LootSystem.roll_table: table_id is empty")
		return LootRollResult.new()
	if not ServiceRegistry.has_service("content"):
		push_error("LootSystem.roll_table: missing ContentRegistry service")
		return LootRollResult.new()
	var content := ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		push_error("LootSystem.roll_table: ContentRegistry service is invalid")
		return LootRollResult.new()
	var table := content.get_resource(table_id) as LootTableDefinition
	if table == null:
		push_warning("LootSystem.roll_table: table not found: %s" % table_id)
		return LootRollResult.new()
	return roll(table, context if context != null else GameplayContext.new())


func roll(table: LootTableDefinition, context: GameplayContext) -> LootRollResult:
	var result := LootRollResult.new()
	if table == null:
		push_error("LootSystem.roll: table is null")
		return result
	if table.rolls <= 0:
		return result
	var ctx := context if context != null else GameplayContext.new()
	var random: RandomService = null
	if ServiceRegistry.has_service("random"):
		random = ServiceRegistry.get_service("random") as RandomService
	for _i in range(table.rolls):
		var candidates := _get_valid_entries(table, ctx)
		var total_weight := table.empty_weight if table.allow_empty else 0.0
		for entry in candidates:
			total_weight += max(0.0, entry.weight)
		if total_weight <= 0:
			continue
		var r := (
			random.randf_range(0.0, total_weight)
			if random != null
			else randf_range(0.0, total_weight)
		)
		if table.allow_empty and r < table.empty_weight:
			result.debug_rolls.append({"roll": r, "result": "empty"})
			continue
		var cursor := table.empty_weight if table.allow_empty else 0.0
		for entry in candidates:
			cursor += max(0.0, entry.weight)
			if r <= cursor:
				var quantity := _roll_quantity(entry, random)
				if quantity > 0 and entry.content_id.strip_edges() != "":
					result.item_instances.append(ItemInstance.create(entry.content_id, quantity))
					result.debug_rolls.append(
						{"roll": r, "result": entry.content_id, "quantity": quantity}
					)
				else:
					result.debug_rolls.append({"roll": r, "result": "invalid_entry"})
				break
	return result


func _get_valid_entries(table: LootTableDefinition, context: GameplayContext) -> Array[LootEntry]:
	var result: Array[LootEntry] = []
	for entry in table.entries:
		if entry == null:
			continue
		if entry.content_id.strip_edges() == "":
			continue
		if ConditionEvaluator.evaluate_all(entry.conditions, context):
			result.append(entry)
	return result


func _roll_quantity(entry: LootEntry, random: RandomService) -> int:
	if entry == null:
		return 0
	var min_quantity := min(entry.min_quantity, entry.max_quantity)
	var max_quantity := max(entry.min_quantity, entry.max_quantity)
	if min_quantity == max_quantity:
		return max(0, min_quantity)
	if random != null:
		return max(0, random.randi_range(min_quantity, max_quantity))
	return max(0, randi_range(min_quantity, max_quantity))
