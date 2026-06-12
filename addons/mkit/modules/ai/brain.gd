class_name Brain
extends Node
## 说明：`Brain` 是 AI 系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在AI 系统中复用这段契约或状态时使用它。
## 示例：`var instance := Brain.new()`

## 是否启用该运行逻辑；关闭后节点保留但不主动思考或执行。
@export var enabled: bool = true
## AI 思考间隔，单位为秒；值越小响应越快但调用越频繁。
@export var think_interval: float = 0.2
var _timer: float = 0.0
## AI 发送命令时使用的 CommandReceiver；准备阶段从拥有者节点解析。
var command_receiver: CommandReceiver = null
## 本次行为或结果作用的目标节点；为空表示尚未选定目标。
var target: Node = null
## 跨状态或 AI 决策共享的临时键值数据；同一拥有者生命周期内复用。
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
