class_name QuestDefinition
extends ContentDefinition
## 说明：`QuestDefinition` 是 任务系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `QuestDefinition` 资源，再通过 ContentService 按 id 查询。

## 编辑器配置：`quest_id` 表示稳定 id，由 `QuestDefinition` 的公开 API 读取或维护。
@export var quest_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `QuestDefinition` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`description` 表示说明文本，由 `QuestDefinition` 的公开 API 读取或维护。
@export_multiline var description: String = ""
## 编辑器配置：`quest_type` 表示 `QuestDefinition` 的字段值，由 `QuestDefinition` 的公开 API 读取或维护。
@export var quest_type: String = "side"
## 编辑器配置：`objectives` 表示 `QuestDefinition` 的字段值，由 `QuestDefinition` 的公开 API 读取或维护。
@export var objectives: Array[QuestObjectiveDefinition] = []
## 编辑器配置：`prerequisite_quest_ids` 表示稳定 id 列表，由 `QuestDefinition` 的公开 API 读取或维护。
@export var prerequisite_quest_ids: Array[String] = []
## 编辑器配置：`accept_conditions` 表示执行条件列表，由 `QuestDefinition` 的公开 API 读取或维护。
@export var accept_conditions: Array[Condition] = []
## 编辑器配置：`reward_effects` 表示效果列表，由 `QuestDefinition` 的公开 API 读取或维护。
@export var reward_effects: Array[GameEffect] = []
## 编辑器配置：`auto_complete` 表示 `QuestDefinition` 的字段值，由 `QuestDefinition` 的公开 API 读取或维护。
@export var auto_complete: bool = false
## 编辑器配置：`repeatable` 表示 `QuestDefinition` 的字段值，由 `QuestDefinition` 的公开 API 读取或维护。
@export var repeatable: bool = false
## 编辑器配置：`tags` 表示标签集合，由 `QuestDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `QuestDefinition` 的领域契约一致。
func get_content_id() -> String:
	return quest_id


## 返回 `objective` 对应的数据或对象，并保持 `QuestDefinition` 的领域契约一致。
func get_objective(objective_id: String) -> QuestObjectiveDefinition:
	for objective in objectives:
		if objective != null and objective.objective_id == objective_id:
			return objective
	return null
