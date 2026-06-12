class_name LootDropResult
extends RefCounted
## 说明：`LootDropResult` 是 掉落与奖励系统 的结果对象，负责承载一次死亡掉落桥接的匹配和 roll 输出。
## 上游：通常由 DeathLootService 创建。
## 下游：会连接 EventService、游戏侧背包交付、地面拾取物或 UI 展示，不直接依赖具体游戏内容。
## 使用：监听 `LootEvents.LOOT_DROPPED` 后从事件 payload 的 `drop` 读取。
## 示例：`var drop := event.payload.get("drop") as LootDropResult`

## 触发本次掉落的 DeathLootRuleDefinition id。
var rule_id: String = ""
## 本次 roll 使用的 LootTableDefinition id。
var loot_table_id: String = ""
## 死亡实体的运行时 id。
var entity_id: String = ""
## 死亡实体的 EntityDefinition id。
var entity_definition_id: String = ""
## 死亡实体节点引用；若实体已释放，调用方应只依赖 id 字段。
var entity_ref: Node = null
## 击杀者运行时 id；没有击杀者时为空。
var killer_id: String = ""
## 击杀者节点引用；没有击杀者时为 null。
var killer_ref: Node = null
## LootService 已 roll 好的结果；交付方式由游戏侧决定。
var roll_result: LootRollResult = null


## 判断本次掉落是否包含实际可交付内容，并保持 `LootDropResult` 的领域契约一致。
func has_content() -> bool:
	return roll_result != null and (
		not roll_result.item_instances.is_empty() or not roll_result.currency.is_empty()
	)
