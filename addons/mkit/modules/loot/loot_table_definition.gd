class_name LootTableDefinition
extends ContentDefinition
## 说明：`LootTableDefinition` 是 掉落与奖励系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `LootTableDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`loot_table_id` 表示稳定 id，由 `LootTableDefinition` 的公开 API 读取或维护。
@export var loot_table_id: String = ""
## 编辑器配置：`rolls` 表示 `LootTableDefinition` 的字段值，由 `LootTableDefinition` 的公开 API 读取或维护。
@export var rolls: int = 1
## 编辑器配置：`entries` 表示 `LootTableDefinition` 的字段值，由 `LootTableDefinition` 的公开 API 读取或维护。
@export var entries: Array[LootEntry] = []
## 编辑器配置：`allow_empty` 表示 `LootTableDefinition` 的字段值，由 `LootTableDefinition` 的公开 API 读取或维护。
@export var allow_empty: bool = true
## 编辑器配置：`empty_weight` 表示 `LootTableDefinition` 的字段值，由 `LootTableDefinition` 的公开 API 读取或维护。
@export var empty_weight: float = 0.0


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `LootTableDefinition` 的领域契约一致。
func get_content_id() -> String:
	return loot_table_id
