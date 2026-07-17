class_name EntitySaveAgent
extends Node
## 说明：`EntitySaveAgent` 是 存档系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在存档系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntitySaveAgent.new()`


## 稳定标识 `ENTITY_SAVE_PARTICIPANT_GROUP`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ENTITY_SAVE_PARTICIPANT_GROUP: String = "mkit_entity_save_participant"
## 运行时实体 id；保存、命令路由和事件归因使用它定位同一个实体。
@export var entity_id: String = ""
## 要加载或实例化的场景路径；应填写 res:// 开头的 .tscn 资源。
@export var scene_path: String = ""
## ZoneDefinition 在 ContentService 中的稳定 id。
@export var zone_id: String = ""
## 参与保存的根节点路径；为空时使用 EntitySaveAgent 所在节点。
@export var root_path: NodePath = NodePath("")
## 恢复存档时的排序权重；数值越小越早恢复。
@export var restore_order: int = 0
## 保存实体时是否包含符合 save/load duck typing 的参与节点。
@export var include_duck_participants: bool = true
var _last_errors: Array[String] = []


## 读取当前对象中的 `entity_id`；未找到时返回 null、空集合或该 API 的默认值。
func get_entity_id() -> String:
	return entity_id.strip_edges()


## 执行 `to_entity_save_record` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func to_entity_save_record() -> Dictionary:
	_last_errors.clear()
	var root := _resolve_root()
	var components: Dictionary = {}
	if root == null:
		_last_errors.append("missing entity root: %s" % get_entity_id())
		return _make_record(components)
	for node in _collect_participants(root):
		var key := str(node.call("get_save_key")).strip_edges()
		if key == "":
			_last_errors.append("empty component save key on entity: %s" % get_entity_id())
			continue
		if components.has(key):
			_last_errors.append(
				"duplicate component save key: %s on entity: %s" % [key, get_entity_id()]
			)
			continue
		var raw_data = node.call("to_save_data")
		if not (raw_data is Dictionary):
			_last_errors.append(
				"component save data is not a Dictionary: %s on entity: %s"
				% [key, get_entity_id()]
			)
			continue
		components[key] = raw_data
	return _make_record(components)


## 将传入 payload 或 effect 应用到目标对象；返回值、signal 或 event 表示实际结果。
func apply_entity_save_record(record: Dictionary) -> void:
	_last_errors.clear()
	var root := _resolve_root()
	if root == null:
		_last_errors.append("missing entity root: %s" % get_entity_id())
		return
	var raw_components = record.get("components", {})
	var components: Dictionary = {}
	if raw_components is Dictionary:
		components = raw_components
	var restored: Dictionary = {}
	for node in _collect_participants(root):
		var key := str(node.call("get_save_key")).strip_edges()
		if key == "" or not components.has(key):
			continue
		var raw_data = components[key]
		if raw_data is Dictionary:
			node.call("from_save_data", raw_data)
			restored[key] = true
	for raw_key in components.keys():
		var key := str(raw_key)
		if not restored.has(key):
			_last_errors.append(
				"missing component for save key: %s on entity: %s" % [key, get_entity_id()]
			)


## 检查当前集合或对象是否包含 `save_errors`；缺失或空值时返回 false。
func has_save_errors() -> bool:
	return not _last_errors.is_empty()


## 读取当前对象中的 `save_errors`；未找到时返回 null、空集合或该 API 的默认值。
func get_save_errors() -> Array[String]:
	var result: Array[String] = []
	for error in _last_errors:
		result.append(error)
	return result


func _make_record(components: Dictionary) -> Dictionary:
	return {
		"scene_path": scene_path,
		"zone_id": zone_id,
		"components": components,
	}


func _resolve_root() -> Node:
	if root_path != NodePath(""):
		var explicit := get_node_or_null(root_path)
		if explicit != null:
			return explicit
	if owner != null:
		return owner
	return get_parent()


func _collect_participants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if node == self:
			continue
		if _is_participant(node):
			result.append(node)
	return result


func _is_participant(node: Node) -> bool:
	if node is SaveableComponent:
		return true
	return (
		include_duck_participants
		and node.is_in_group(ENTITY_SAVE_PARTICIPANT_GROUP)
		and node.has_method("get_save_key")
		and node.has_method("to_save_data")
		and node.has_method("from_save_data")
	)
