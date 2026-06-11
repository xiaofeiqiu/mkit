class_name ItemDefinition
extends ContentDefinition
## 说明：`ItemDefinition` 是 背包与装备系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `ItemDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`item_id` 表示稳定 id，由 `ItemDefinition` 的公开 API 读取或维护。
@export var item_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `ItemDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`description` 表示说明文本，由 `ItemDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`item_type` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var item_type: String = "material"
## 编辑器配置：`rarity` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var rarity: String = "common"
## 编辑器配置：`value` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var value: int = 0
## 编辑器配置：`icon` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var icon: Texture2D
## 编辑器配置：`stackable` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var stackable: bool = true
## 编辑器配置：`max_stack` 表示最大值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var max_stack: int = 99
## 编辑器配置：`equipment_slot` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var equipment_slot: String = ""
## 编辑器配置：`tags` 表示标签集合，由 `ItemDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`use_conditions` 表示执行条件列表，由 `ItemDefinition` 的公开 API 读取或维护。
@export var use_conditions: Array[Condition] = []
## 编辑器配置：`use_effects` 表示效果列表，由 `ItemDefinition` 的公开 API 读取或维护。
@export var use_effects: Array[GameEffect] = []
## 编辑器配置：`stat_modifiers` 表示 `ItemDefinition` 的字段值，由 `ItemDefinition` 的公开 API 读取或维护。
@export var stat_modifiers: Array[StatModifierDefinition] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `ItemDefinition` 的领域契约一致。
func get_content_id() -> String:
	return item_id
