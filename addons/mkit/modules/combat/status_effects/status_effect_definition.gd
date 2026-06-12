class_name StatusEffectDefinition
extends ContentDefinition
## 说明：`StatusEffectDefinition` 是 状态效果系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `StatusEffectDefinition` 资源，再通过 ContentService 按 id 查询。

## 公开枚举 `StackRule`，限定 `StatusEffectDefinition` 可接受的配置或运行时状态取值。
enum StackRule { REFRESH_DURATION, ADD_STACK, REPLACE, IGNORE, EXTEND_DURATION, INDEPENDENT_STACKS }
## ContentService 注册状态效果定义时使用的稳定 id；StatusEffectController 按它创建状态实例。
@export var status_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 状态默认持续时间，单位为秒；小于 0 可由调用方约定为永久。
@export var duration: float = 5.0
## 状态 tick 间隔秒数；小于等于 0 时通常不产生周期 tick。
@export var tick_interval: float = 1.0
## 允许叠加的最大层数；1 表示不可叠加。
@export var max_stacks: int = 1
## 重复施加同一状态时的处理规则；决定刷新时长、增加层数或忽略。
@export var stack_rule: StackRule = StackRule.REFRESH_DURATION
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 状态首次施加时按顺序执行的效果列表。
@export var effects_on_apply: Array[GameEffect] = []
## 状态每次 tick 时按顺序执行的效果列表。
@export var effects_on_tick: Array[GameEffect] = []
## 状态结束或被移除时按顺序执行的效果列表。
@export var effects_on_remove: Array[GameEffect] = []
## 状态或装备提供的属性修饰列表；应用后由 StatsComponent 参与计算。
@export var stat_modifiers: Array[StatModifierDefinition] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `StatusEffectDefinition` 的领域契约一致。
func get_content_id() -> String:
	return status_id
