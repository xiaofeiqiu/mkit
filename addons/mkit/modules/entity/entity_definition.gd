class_name EntityDefinition
extends ContentDefinition
## 说明：`EntityDefinition` 是 实体系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `EntityDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`entity_definition_id` 表示稳定 id，由 `EntityDefinition` 的公开 API 读取或维护。
@export var entity_definition_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `EntityDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`scene_path` 表示资源或节点路径，由 `EntityDefinition` 的公开 API 读取或维护。
@export var scene_path: String = ""
## 编辑器配置：`default_faction` 表示 `EntityDefinition` 的字段值，由 `EntityDefinition` 的公开 API 读取或维护。
@export var default_faction: String = "neutral"
## 编辑器配置：`tags` 表示标签集合，由 `EntityDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`base_stats` 表示 `EntityDefinition` 的字段值，由 `EntityDefinition` 的公开 API 读取或维护。
@export var base_stats: Dictionary = {}
## 编辑器配置：`starting_ability_ids` 表示稳定 id 列表，由 `EntityDefinition` 的公开 API 读取或维护。
@export var starting_ability_ids: Array[String] = []
## 编辑器配置：`loot_table_id` 表示稳定 id，由 `EntityDefinition` 的公开 API 读取或维护。
@export var loot_table_id: String = ""


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `EntityDefinition` 的领域契约一致。
func get_content_id() -> String:
	return entity_definition_id
