class_name StatModifier
extends RefCounted
## 说明：`StatModifier` 是 属性系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在属性系统中复用这段契约或状态时使用它。
## 示例：`var instance := StatModifier.new()`

## 运行时状态：`modifier_id` 表示稳定 id，由 `StatModifier` 的公开 API 读取或维护。
var modifier_id: String = ""
## 运行时状态：`stat_id` 表示稳定 id，由 `StatModifier` 的公开 API 读取或维护。
var stat_id: String = ""
## 运行时状态：`source_id` 表示稳定 id，由 `StatModifier` 的公开 API 读取或维护。
var source_id: String = ""
## 运行时状态：`operation` 表示 `StatModifier` 的字段值，由 `StatModifier` 的公开 API 读取或维护。
var operation: StatModifierDefinition.Operation
## 运行时状态：`value` 表示 `StatModifier` 的字段值，由 `StatModifier` 的公开 API 读取或维护。
var value: float = 0.0
## 运行时状态：`priority` 表示 `StatModifier` 的字段值，由 `StatModifier` 的公开 API 读取或维护。
var priority: int = 0
## 运行时状态：`stacking_rule` 表示 `StatModifier` 的字段值，由 `StatModifier` 的公开 API 读取或维护。
var stacking_rule: StatModifierDefinition.StackingRule
## 运行时状态：`remaining_duration` 表示持续时间，由 `StatModifier` 的公开 API 读取或维护。
var remaining_duration: float = -1.0
## 运行时状态：`tags` 表示标签集合，由 `StatModifier` 的公开 API 读取或维护。
var tags: Array[String] = []


## 执行 `from_definition` 对应的公开操作，并保持 `StatModifier` 的领域契约一致。
static func from_definition(
	definition: StatModifierDefinition, source: String, duration: float = -1.0
) -> StatModifier:
	var m := StatModifier.new()
	m.modifier_id = definition.modifier_id
	m.stat_id = definition.stat_id
	m.source_id = source
	m.operation = definition.operation
	m.value = definition.value
	m.priority = definition.priority
	m.stacking_rule = definition.stacking_rule
	m.remaining_duration = duration
	m.tags = definition.tags.duplicate()
	return m


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `StatModifier` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {
		"modifier_id": modifier_id,
		"stat_id": stat_id,
		"source_id": source_id,
		"operation": int(operation),
		"value": value,
		"priority": priority,
		"stacking_rule": int(stacking_rule),
		"remaining_duration": remaining_duration,
		"tags": tags.duplicate()
	}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `StatModifier` 的领域契约一致。
static func from_save_data(data: Dictionary) -> StatModifier:
	var m := StatModifier.new()
	m.modifier_id = str(data.get("modifier_id", ""))
	m.stat_id = str(data.get("stat_id", ""))
	m.source_id = str(data.get("source_id", ""))
	m.operation = data.get("operation", StatModifierDefinition.Operation.FLAT_ADD)
	m.value = float(data.get("value", 0.0))
	m.priority = int(data.get("priority", 0))
	m.stacking_rule = data.get("stacking_rule", StatModifierDefinition.StackingRule.STACK)
	m.remaining_duration = float(data.get("remaining_duration", -1.0))
	m.tags = []
	for tag in data.get("tags", []):
		m.tags.append(str(tag))
	return m
