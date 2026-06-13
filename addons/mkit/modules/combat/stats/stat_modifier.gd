class_name StatModifier
extends RefCounted
## 说明：`StatModifier` 是 属性系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在属性系统中复用这段契约或状态时使用它。
## 示例：`var instance := StatModifier.new()`

## 引用的 StatModifier id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var modifier_id: String = ""
## 引用的 StatDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var stat_id: String = ""
## 事件、命令或修饰器来源 id；通常对应 EntityIdentity、系统或内容定义。
var source_id: String = ""
## 属性修饰运算类型；决定 value 是加法、倍率还是覆盖等规则。
var operation: StatModifierDefinition.Operation
## 属性或修饰器数值；具体含义由 operation 或所在定义决定。
var value: float = 0.0
## 属性修饰应用优先级；数值越小越早参与计算。
var priority: int = 0
## 同源或同类修饰叠加规则；决定重复应用时覆盖、刷新还是累加。
var stacking_rule: StatModifierDefinition.StackingRule
## 剩余持续时间，单位为秒；负数通常表示永久效果。
var remaining_duration: float = -1.0
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
var tags: Array[String] = []


## 执行 `from_definition` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
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


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
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


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
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
