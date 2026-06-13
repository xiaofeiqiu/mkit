class_name LootService
extends RefCounted
## 说明：`LootService` 是 掉落与奖励系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(LootService.SERVICE_ID, LootService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `LootService`。
const SERVICE_ID: String = "loot"


## 根据权重或随机服务生成结果；返回值、signal 或事件会表达实际执行结果。
func roll_table(table_id: String, context: GameplayContext) -> LootRollResult:
	if table_id.strip_edges() == "":
		push_warning("LootService.roll_table: table_id is empty")
		return LootRollResult.new()
	var content := Mkit.content()
	if content == null:
		push_warning("LootService.roll_table: missing ContentService service")
		return LootRollResult.new()
	var table := content.get_resource(table_id) as LootTableDefinition
	if table == null:
		push_warning("LootService.roll_table: table not found: %s" % table_id)
		return LootRollResult.new()
	return roll(table, GameplayContext.from_context(context))


## 根据权重或随机服务生成结果；返回值、signal 或事件会表达实际执行结果。
func roll(table: LootTableDefinition, context: GameplayContext) -> LootRollResult:
	var result := LootRollResult.new()
	if table == null:
		push_warning("LootService.roll: table is null")
		return result
	if table.rolls <= 0:
		return result
	var ctx := GameplayContext.from_context(context)
	var random: RandomService = Mkit.random()
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


## 读取配置资源生成运行时对象或结果；输入为空或无效时返回空结果。
func generate_options(
	pool_ids: Array[String], count: int, context: GameplayContext
) -> Array[RewardOption]:
	return RewardSystem.new().generate_options(pool_ids, count, context)


## 将传入 payload 或 effect 应用到目标对象；返回值、signal 或 event 表示实际结果。
func apply_selected(option: RewardOption, context: GameplayContext) -> bool:
	return RewardSystem.new().apply_selected(option, context)
