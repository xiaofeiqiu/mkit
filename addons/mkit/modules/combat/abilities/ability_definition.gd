class_name AbilityDefinition
extends ContentDefinition
## 说明：`AbilityDefinition` 是 能力系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `AbilityDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册能力定义时使用的稳定 id；AbilityController 按它授予和施放能力。
@export var ability_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## UI 展示用图标资源；为 null 时界面应使用默认图标或隐藏图标位。
@export var icon: Texture2D
## 能力施放后的冷却秒数；charges 大于 1 时每个周期回充一层。
@export var cooldown: float = 1.0
## 能力可储存的使用次数上限；1 表示普通冷却，2 以上可连续使用后逐层回充。
@export var charges: int = 1
## 能力消耗的资源 id；`none` 表示不消耗资源，其他值应对应 ResourcePoolComponent 中的资源。
@export var cost_type: String = "none"
## 每次施放消耗的资源数量；cost_type 为 `none` 时忽略。
@export var cost_amount: float = 0.0
## 施放前摇时间，单位为秒；0 表示立即执行效果。
@export var cast_time: float = 0.0
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
## 条件通过后按顺序执行的效果列表；每个元素应为 GameEffect 资源。
@export var effects: Array[GameEffect] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `AbilityDefinition` 的领域契约一致。
func get_content_id() -> String:
	return ability_id
