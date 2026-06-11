class_name AbilityDefinition
extends ContentDefinition
## 说明：`AbilityDefinition` 是 能力系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `AbilityDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`ability_id` 表示稳定 id，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var ability_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`description` 表示说明文本，由 `AbilityDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`icon` 表示 `AbilityDefinition` 的字段值，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var icon: Texture2D
## 编辑器配置：`cooldown` 表示冷却时间，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var cooldown: float = 1.0
## 编辑器配置：`charges` 表示 `AbilityDefinition` 的字段值，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var charges: int = 1
## 编辑器配置：`cost_type` 表示消耗配置，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var cost_type: String = "none"
## 编辑器配置：`cost_amount` 表示数量值，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var cost_amount: float = 0.0
## 编辑器配置：`cast_time` 表示 `AbilityDefinition` 的字段值，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var cast_time: float = 0.0
## 编辑器配置：`range` 表示距离或范围，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var range: float = 0.0
## 编辑器配置：`tags` 表示标签集合，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`conditions` 表示执行条件列表，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
## 编辑器配置：`effects` 表示效果列表，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var effects: Array[GameEffect] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `AbilityDefinition` 的领域契约一致。
func get_content_id() -> String:
	return ability_id
