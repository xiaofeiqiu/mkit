class_name StatusEffectInstance
extends RefCounted
## 说明：`StatusEffectInstance` 是 状态效果系统 的运行时实例，负责保存由定义资源派生出的可变状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在状态效果系统中复用这段契约或状态时使用它。
## 示例：`var instance := StatusEffectInstance.new()`

## 运行时实例 id；用于区分同一内容定义产生的多个实例。
var instance_id: String = ""
## 该状态实例来源的 StatusEffectDefinition id。
var definition_id: String = ""
## 事件、命令或修饰器来源 id；通常对应 EntityIdentity、系统或内容定义。
var source_id: String = ""
## 产生本次行为或结果的节点引用；为空表示来源未绑定或不需要来源。
var source: Node = null
## 本次行为或结果作用的目标节点；为空表示尚未选定目标。
var target: Node = null
## 剩余持续时间，单位为秒；负数通常表示永久效果。
var remaining_duration: float = 0.0
## 距离下一次状态 tick 的剩余秒数。
var tick_timer: float = 0.0
## 状态或效果层数；应大于 0，并受定义的最大层数限制。
var stacks: int = 1
## 该状态已经施加到 StatsComponent 的修饰器 id 列表；移除时用于清理。
var applied_modifier_ids: Array[String] = []


## 初始化运行时依赖和起始状态，并保持 `StatusEffectInstance` 的领域契约一致。
func setup(
	definition: StatusEffectDefinition,
	source_entity: Node,
	target_entity: Node,
	initial_stacks: int,
	duration_override: float = -1.0
) -> void:
	instance_id = "%s_%d" % [definition.status_id, Time.get_ticks_usec()]
	definition_id = definition.status_id
	source_id = ""
	source = source_entity
	target = target_entity
	stacks = initial_stacks
	remaining_duration = duration_override if duration_override > 0 else definition.duration
	tick_timer = definition.tick_interval
