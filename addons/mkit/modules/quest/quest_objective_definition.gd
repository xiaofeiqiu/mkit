class_name QuestObjectiveDefinition
extends Resource
## 说明：`QuestObjectiveDefinition` 是 任务系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `QuestObjectiveDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`objective_id` 表示稳定 id，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var objective_id: String = ""
## 编辑器配置：`description` 表示说明文本，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`event_type` 表示 `QuestObjectiveDefinition` 的字段值，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var event_type: String = ""
## 编辑器配置：`match_key` 表示 `QuestObjectiveDefinition` 的字段值，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var match_key: String = ""
## 编辑器配置：`match_value` 表示 `QuestObjectiveDefinition` 的字段值，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var match_value: String = ""
## 编辑器配置：`count_payload_key` 表示事件或存档载荷，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var count_payload_key: String = ""
## 编辑器配置：`required_count` 表示数量上限或计数，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var required_count: int = 1
## 编辑器配置：`optional` 表示 `QuestObjectiveDefinition` 的字段值，由 `QuestObjectiveDefinition` 的公开 API 读取或维护。
@export var optional: bool = false
