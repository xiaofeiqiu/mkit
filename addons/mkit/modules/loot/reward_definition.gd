class_name RewardDefinition
extends ContentDefinition
## 说明：`RewardDefinition` 是 掉落与奖励系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `RewardDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`reward_id` 表示稳定 id，由 `RewardDefinition` 的公开 API 读取或维护。
@export var reward_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `RewardDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`description` 表示说明文本，由 `RewardDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`icon` 表示 `RewardDefinition` 的字段值，由 `RewardDefinition` 的公开 API 读取或维护。
@export var icon: Texture2D
## 编辑器配置：`rarity` 表示 `RewardDefinition` 的字段值，由 `RewardDefinition` 的公开 API 读取或维护。
@export var rarity: String = "common"
## 编辑器配置：`weight` 表示 `RewardDefinition` 的字段值，由 `RewardDefinition` 的公开 API 读取或维护。
@export var weight: float = 1.0
## 编辑器配置：`conditions` 表示执行条件列表，由 `RewardDefinition` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
## 编辑器配置：`effects` 表示效果列表，由 `RewardDefinition` 的公开 API 读取或维护。
@export var effects: Array[GameEffect] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `RewardDefinition` 的领域契约一致。
func get_content_id() -> String:
	return reward_id
