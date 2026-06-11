class_name StatusEffectDefinition
extends ContentDefinition
## 说明：`StatusEffectDefinition` 是 状态效果系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `StatusEffectDefinition` 资源，再通过 ContentService 按 id 查询。

## 公开枚举 `StackRule`，限定 `StatusEffectDefinition` 可接受的配置或运行时状态取值。
enum StackRule { REFRESH_DURATION, ADD_STACK, REPLACE, IGNORE, EXTEND_DURATION, INDEPENDENT_STACKS }
## 编辑器配置：`status_id` 表示稳定 id，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var status_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`duration` 表示持续时间，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var duration: float = 5.0
## 编辑器配置：`tick_interval` 表示时间间隔，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var tick_interval: float = 1.0
## 编辑器配置：`max_stacks` 表示最大值，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var max_stacks: int = 1
## 编辑器配置：`stack_rule` 表示 `StatusEffectDefinition` 的字段值，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var stack_rule: StackRule = StackRule.REFRESH_DURATION
## 编辑器配置：`tags` 表示标签集合，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`effects_on_apply` 表示效果列表，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var effects_on_apply: Array[GameEffect] = []
## 编辑器配置：`effects_on_tick` 表示效果列表，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var effects_on_tick: Array[GameEffect] = []
## 编辑器配置：`effects_on_remove` 表示效果列表，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var effects_on_remove: Array[GameEffect] = []
## 编辑器配置：`stat_modifiers` 表示 `StatusEffectDefinition` 的字段值，由 `StatusEffectDefinition` 的公开 API 读取或维护。
@export var stat_modifiers: Array[StatModifierDefinition] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `StatusEffectDefinition` 的领域契约一致。
func get_content_id() -> String:
	return status_id
