class_name CommandReceiver
extends Node
## 说明：`CommandReceiver` 是 命令路由 的命令接收器，负责把 GameCommand 转交给实体状态机或本地处理逻辑。
## 上游：通常由 CommandService 或直接持有目标实体的脚本创建或调用。
## 下游：会连接StateMachine、命令历史和未处理命令 hook，不直接依赖具体游戏内容。
## 使用：当项目实体需要被 CommandService 通过 target_id 路由命令时使用它。
## 示例：`var instance := CommandReceiver.new()`

## 编辑器配置：`receiver_id` 表示稳定 id，由 `CommandReceiver` 的公开 API 读取或维护。
@export var receiver_id: String = ""
## 编辑器配置：`auto_register` 表示 `CommandReceiver` 的字段值，由 `CommandReceiver` 的公开 API 读取或维护。
@export var auto_register: bool = true
## 运行时状态：`owner_entity` 表示 `CommandReceiver` 的字段值，由 `CommandReceiver` 的公开 API 读取或维护。
var owner_entity: Node = null
## 运行时状态：`state_machine` 表示运行时状态，由 `CommandReceiver` 的公开 API 读取或维护。
var state_machine: StateMachine = null
## 运行时状态：`command_history` 表示 `CommandReceiver` 的字段值，由 `CommandReceiver` 的公开 API 读取或维护。
var command_history: Array[GameCommand] = []
## 运行时状态：`max_history` 表示最大值，由 `CommandReceiver` 的公开 API 读取或维护。
var max_history: int = 20
var _registered_router: CommandService = null


func _ready() -> void:
	owner_entity = owner if owner != null else get_parent()
	_resolve_state_machine()
	if receiver_id == "":
		var identity := EntityContract.get_identity(owner_entity)
		if identity != null and "entity_id" in identity:
			receiver_id = str(identity.entity_id)
	_register_with_router()


func _process(_delta: float) -> void:
	if state_machine == null:
		_resolve_state_machine()
	if auto_register and _registered_router == null:
		_register_with_router()
	if state_machine != null and (not auto_register or _registered_router != null):
		set_process(false)


func _exit_tree() -> void:
	if _registered_router != null and receiver_id != "":
		_registered_router.unregister_receiver(receiver_id)
	_registered_router = null


## 执行 `configure_receiver_id` 对应的公开操作，并保持 `CommandReceiver` 的领域契约一致。
func configure_receiver_id(id: String) -> void:
	if id == "":
		return
	if _registered_router != null and receiver_id != id:
		_registered_router.unregister_receiver(receiver_id)
		_registered_router = null
	receiver_id = id
	_register_with_router()


## 接收外部传入的数据并交给本地处理，并保持 `CommandReceiver` 的领域契约一致。
func receive_command(command: GameCommand) -> bool:
	if command == null:
		push_warning("CommandReceiver.receive_command: command is null")
		return false
	if state_machine == null:
		_resolve_state_machine()
	_record_command(command)
	if state_machine != null:
		var handled := state_machine.handle_command(command)
		if handled:
			command.mark_consumed()
			return true
	var fallback_handled := handle_unhandled_command(command)
	if fallback_handled:
		command.mark_consumed()
	return fallback_handled


## 处理传入命令、事件或状态变化，并保持 `CommandReceiver` 的领域契约一致。
func handle_unhandled_command(command: GameCommand) -> bool:
	return false


func _record_command(command: GameCommand) -> void:
	if command == null:
		return
	command_history.append(command)
	if command_history.size() > max_history:
		command_history.pop_front()


func _resolve_state_machine() -> void:
	state_machine = null
	if owner_entity == null:
		return
	state_machine = EntityContract.get_state_machine(owner_entity)


func _register_with_router() -> void:
	if not auto_register:
		set_process(state_machine == null)
		return
	if receiver_id == "":
		push_warning("CommandReceiver auto_register skipped: receiver_id is empty")
		set_process(true)
		return
	if not ServiceRegistry.has_service(CommandService.SERVICE_ID):
		set_process(true)
		return
	var router := ServiceRegistry.get_port(CommandService.SERVICE_ID) as CommandService
	if router == null:
		set_process(true)
		return
	router.register_receiver(receiver_id, self)
	_registered_router = router
	set_process(state_machine == null)
