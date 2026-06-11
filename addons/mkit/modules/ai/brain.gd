class_name Brain
extends Node
## 说明：`Brain` 是 AI 系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在AI 系统中复用这段契约或状态时使用它。
## 示例：`var instance := Brain.new()`

## 编辑器配置：`enabled` 表示是否启用，由 `Brain` 的公开 API 读取或维护。
@export var enabled: bool = true
## 编辑器配置：`think_interval` 表示时间间隔，由 `Brain` 的公开 API 读取或维护。
@export var think_interval: float = 0.2
var _timer: float = 0.0
## 运行时状态：`command_receiver` 表示 `Brain` 的字段值，由 `Brain` 的公开 API 读取或维护。
var command_receiver: CommandReceiver = null
## 运行时状态：`target` 表示 `Brain` 的字段值，由 `Brain` 的公开 API 读取或维护。
var target: Node = null
## 运行时状态：`blackboard` 表示 `Brain` 的字段值，由 `Brain` 的公开 API 读取或维护。
var blackboard: Blackboard = Blackboard.new()


func _ready() -> void:
	command_receiver = EntityContract.get_command_receiver(self)


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer -= delta
	if _timer <= 0:
		_timer = think_interval
		think()


## 执行 `think` 对应的公开操作，并保持 `Brain` 的领域契约一致。
func think() -> void:
	pass


## 执行 `issue_command` 对应的公开操作，并保持 `Brain` 的领域契约一致。
func issue_command(command_type: String, payload: Dictionary = {}) -> bool:
	if command_receiver == null:
		command_receiver = EntityContract.get_command_receiver(self)
	if command_receiver == null:
		return false
	var source_id := _get_owner_id()
	var cmd := GameCommand.create(command_type, source_id, source_id, payload)
	return command_receiver.receive_command(cmd)


func _get_owner_id() -> String:
	var identity := EntityContract.get_identity(owner)
	return identity.entity_id if identity != null else owner.name
