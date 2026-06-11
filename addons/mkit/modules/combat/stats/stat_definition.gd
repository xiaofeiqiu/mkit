class_name StatDefinition
extends ContentDefinition
## 说明：`StatDefinition` 是 属性系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `StatDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`stat_id` 表示稳定 id，由 `StatDefinition` 的公开 API 读取或维护。
@export var stat_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `StatDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`default_value` 表示 `StatDefinition` 的字段值，由 `StatDefinition` 的公开 API 读取或维护。
@export var default_value: float = 0.0
## 编辑器配置：`min_value` 表示最小值，由 `StatDefinition` 的公开 API 读取或维护。
@export var min_value: float = -INF
## 编辑器配置：`max_value` 表示最大值，由 `StatDefinition` 的公开 API 读取或维护。
@export var max_value: float = INF
## 编辑器配置：`is_percent` 表示 `StatDefinition` 的字段值，由 `StatDefinition` 的公开 API 读取或维护。
@export var is_percent: bool = false


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `StatDefinition` 的领域契约一致。
func get_content_id() -> String:
	return stat_id
