class_name RewardDefinition
extends ContentDefinition
## 说明：`RewardDefinition` 是 掉落与奖励系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `RewardDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册奖励定义时使用的稳定 id；奖励池和 UI 选项按它引用。
@export var reward_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## UI 展示用图标资源；为 null 时界面应使用默认图标或隐藏图标位。
@export var icon: Texture2D
## 稀有度字符串；用于 UI 样式、掉落权重或奖励展示。
@export var rarity: String = "common"
## 随机选择权重；值越大被选中的概率越高，0 表示不会自然选中。
@export var weight: float = 1.0
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
## 条件通过后按顺序执行的效果列表；每个元素应为 GameEffect 资源。
@export var effects: Array[GameEffect] = []


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return reward_id
