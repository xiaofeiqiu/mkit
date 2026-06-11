class_name EntityIdentity
extends Node
## 说明：`EntityIdentity` 是 实体系统 的身份组件，负责保存实体 id、阵营、标签和显示名。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntityIdentity.new()`

## 编辑器配置：`entity_id` 表示稳定 id，由 `EntityIdentity` 的公开 API 读取或维护。
@export var entity_id: String = ""
## 编辑器配置：`definition_id` 表示稳定 id，由 `EntityIdentity` 的公开 API 读取或维护。
@export var definition_id: String = ""
## 编辑器配置：`display_name` 表示面向玩家或编辑器的显示名，由 `EntityIdentity` 的公开 API 读取或维护。
@export var display_name: String = ""
## 编辑器配置：`faction` 表示 `EntityIdentity` 的字段值，由 `EntityIdentity` 的公开 API 读取或维护。
@export var faction: String = "neutral"
## 编辑器配置：`tags` 表示标签集合，由 `EntityIdentity` 的公开 API 读取或维护。
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
