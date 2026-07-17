class_name QuestDefinition
extends ContentDefinition
## 说明：`QuestDefinition` 是 任务系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `QuestDefinition` 资源，再通过 ContentService 按 id 查询。

## ContentService 注册任务时使用的稳定 id；QuestLog 和任务效果按它查找任务状态。
@export var quest_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
@export_multiline var description: String = ""
## 任务类型字符串；例如 main、side、repeatable，由游戏内容约定。
@export var quest_type: String = "side"
## 任务目标定义列表；objective_id 应在同一任务内唯一。
@export var objectives: Array[QuestObjectiveDefinition] = []
## 接受任务前必须完成或满足的任务 id 列表。
@export var prerequisite_quest_ids: Array[String] = []
## 接受任务前需要通过的条件列表。
@export var accept_conditions: Array[Condition] = []
## 任务完成或交付时执行的奖励效果列表。
@export var reward_effects: Array[GameEffect] = []
## 所有必需目标完成后是否自动完成任务。
@export var auto_complete: bool = false
## 任务是否允许重复接受；关闭后完成状态会阻止再次开始。
@export var repeatable: bool = false
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return quest_id


## 读取当前对象中的 `objective`；未找到时返回 null、空集合或该 API 的默认值。
func get_objective(objective_id: String) -> QuestObjectiveDefinition:
	for objective in objectives:
		if objective != null and objective.objective_id == objective_id:
			return objective
	return null
