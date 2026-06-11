class_name StatusEffectInstance
extends RefCounted
## 说明：`StatusEffectInstance` 是 状态效果系统 的运行时实例，负责保存由定义资源派生出的可变状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在状态效果系统中复用这段契约或状态时使用它。
## 示例：`var instance := StatusEffectInstance.new()`

## 运行时状态：`instance_id` 表示稳定 id，由 `StatusEffectInstance` 的公开 API 读取或维护。
var instance_id: String = ""
## 运行时状态：`definition_id` 表示稳定 id，由 `StatusEffectInstance` 的公开 API 读取或维护。
var definition_id: String = ""
## 运行时状态：`source_id` 表示稳定 id，由 `StatusEffectInstance` 的公开 API 读取或维护。
var source_id: String = ""
## 运行时状态：`source` 表示 `StatusEffectInstance` 的字段值，由 `StatusEffectInstance` 的公开 API 读取或维护。
var source: Node = null
## 运行时状态：`target` 表示 `StatusEffectInstance` 的字段值，由 `StatusEffectInstance` 的公开 API 读取或维护。
var target: Node = null
## 运行时状态：`remaining_duration` 表示持续时间，由 `StatusEffectInstance` 的公开 API 读取或维护。
var remaining_duration: float = 0.0
## 运行时状态：`tick_timer` 表示 `StatusEffectInstance` 的字段值，由 `StatusEffectInstance` 的公开 API 读取或维护。
var tick_timer: float = 0.0
## 运行时状态：`stacks` 表示 `StatusEffectInstance` 的字段值，由 `StatusEffectInstance` 的公开 API 读取或维护。
var stacks: int = 1
## 运行时状态：`applied_modifier_ids` 表示稳定 id 列表，由 `StatusEffectInstance` 的公开 API 读取或维护。
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
