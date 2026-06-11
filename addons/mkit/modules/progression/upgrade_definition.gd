class_name UpgradeDefinition
extends ContentDefinition
## 说明：`UpgradeDefinition` 是 成长系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `UpgradeDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`upgrade_id` 表示稳定 id，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var upgrade_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`description` 表示说明文本，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`max_level` 表示最大值，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var max_level: int = 1
## 编辑器配置：`currency_id` 表示稳定 id，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var currency_id: String = "meta_currency"
## 编辑器配置：`cost_by_level` 表示消耗配置，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var cost_by_level: Array[int] = [100]
## 编辑器配置：`prerequisite_upgrade_ids` 表示稳定 id 列表，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var prerequisite_upgrade_ids: Array[String] = []
## 编辑器配置：`unlock_content_ids` 表示稳定 id 列表，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var unlock_content_ids: Array[String] = []
## 编辑器配置：`effects` 表示效果列表，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var effects: Array[GameEffect] = []
## 编辑器配置：`tags` 表示标签集合，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
## 编辑器配置：`is_meta_upgrade` 表示 `UpgradeDefinition` 的字段值，由 `UpgradeDefinition` 的公开 API 读取或维护。
@export var is_meta_upgrade: bool = true


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `UpgradeDefinition` 的领域契约一致。
func get_content_id() -> String:
	return upgrade_id


## 返回 `cost_for_level` 对应的数据或对象，并保持 `UpgradeDefinition` 的领域契约一致。
func get_cost_for_level(next_level: int) -> int:
	var index := max(0, next_level - 1)
	if index >= cost_by_level.size():
		return cost_by_level[-1] if not cost_by_level.is_empty() else 0
	return cost_by_level[index]
