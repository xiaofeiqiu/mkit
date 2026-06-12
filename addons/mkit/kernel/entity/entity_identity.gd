class_name EntityIdentity
extends Node
## 说明：`EntityIdentity` 是 实体系统 的身份组件，负责保存实体 id、阵营、标签和显示名。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntityIdentity.new()`

## 运行时实体 id；保存、命令路由和事件归因使用它定位同一个实体。
@export var entity_id: String = ""
## 实体使用的 EntityDefinition id；为空表示该实体没有绑定静态定义。
@export var definition_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
@export var display_name: String = ""
## 实体阵营标识；战斗过滤、AI 和交互规则可用它判断敌友。
@export var faction: String = "neutral"
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []


func _ready() -> void:
	if entity_id == "":
		entity_id = "%s_%d" % [name.to_snake_case(), Time.get_ticks_usec()]


## 判断是否存在 `tag`，并保持 `EntityIdentity` 的领域契约一致。
func has_tag(tag: String) -> bool:
	return tags.has(tag)


## 判断是否存在 `any_tag`，并保持 `EntityIdentity` 的领域契约一致。
func has_any_tag(input_tags: Array[String]) -> bool:
	for tag in input_tags:
		if tags.has(tag):
			return true
	return false


## 判断 `faction` 当前是否成立，并保持 `EntityIdentity` 的领域契约一致。
func is_faction(value: String) -> bool:
	return faction == value
