class_name DeathLootRuleDefinition
extends ContentDefinition
## 说明：`DeathLootRuleDefinition` 是 掉落与奖励系统 的静态内容定义，负责描述死亡事件到掉落表的匹配规则。
## 上游：通常由 ResourceDatabase 和 ContentService 注册。
## 下游：DeathLootService 会读取它并在匹配死亡事件后 roll 对应 LootTableDefinition。
## 使用：当项目需要配置“某类实体死亡时掉什么”而不污染 EntityDefinition 时使用。
## 示例：配置 `entity_definition_ids` 和 `loot_table_ids` 后加入 ResourceDatabase。

## ContentService 注册死亡掉落规则时使用的稳定 id。
@export var rule_id: String = ""
## 是否启用该规则；关闭后不会参与死亡掉落匹配。
@export var enabled: bool = true
## 多条规则同时匹配时的排序优先级；数值越高越先处理。
@export var priority: int = 0
## 非空时只匹配这些 EntityDefinition id。
@export var entity_definition_ids: Array[String] = []
## 非空时只匹配这些死亡实体阵营。
@export var factions: Array[String] = []
## 非空时死亡实体必须包含全部标签。
@export var required_tags: Array[String] = []
## 非空时死亡实体包含任一标签则排除。
@export var excluded_tags: Array[String] = []
## 额外条件；会在死亡上下文中求值，任一失败则不匹配。
@export var conditions: Array[Condition] = []
## 匹配后依次 roll 的 LootTableDefinition id 列表。
@export var loot_table_ids: Array[String] = []
## 本规则匹配后是否停止处理后续低优先级规则。
@export var stop_after_match: bool = false


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return rule_id


## 判断该规则是否匹配死亡事件；返回值、signal 或事件会表达实际执行结果。
func matches_death_event(event: DomainEvent, context: GameplayContext) -> bool:
	if not enabled or event == null:
		return false
	if not _matches_string_filter(
		str(event.payload.get("definition_id", "")), entity_definition_ids
	):
		return false
	if not _matches_string_filter(str(event.payload.get("faction", "")), factions):
		return false
	var tags: Array = event.payload.get("tags", [])
	for tag in required_tags:
		if not tags.has(tag):
			return false
	for tag in excluded_tags:
		if tags.has(tag):
			return false
	return ConditionEvaluator.evaluate_all(conditions, context)


func _matches_string_filter(value: String, allowed: Array[String]) -> bool:
	return allowed.is_empty() or allowed.has(value)
