class_name CommandReceiver
extends Node
## 说明：`CommandReceiver` 是 命令路由 的命令接收器，负责把 GameCommand 转交给实体状态机或本地处理逻辑。
## 上游：通常由 CommandService 或直接持有目标实体的脚本创建或调用。
## 下游：会连接状态机、命令历史和未处理命令 hook，不直接依赖具体游戏内容。
## 使用：当项目实体需要被 CommandService 通过 target_id 路由命令时使用它。
## 示例：`var instance := CommandReceiver.new()`

## CommandService 路由命令时使用的接收者 id；同一运行场景内应保持唯一。
@export var receiver_id: String = ""
## 进入场景树时是否自动注册到 CommandService；关闭后需要手动注册接收者。
@export var auto_register: bool = true
## 拥有该运行时对象的实体节点；通常是 EntityRoot 或其子节点。
var owner_entity: Node = null
## 绑定到同一实体的状态机引用；可以是 Hfsm 或 Fsm，准备阶段解析后用于转发命令。
var state_machine: StateMachineBase = null
## 最近接收的命令列表；用于调试、测试和有限历史回放。
var command_history: Array[GameCommand] = []
## 保留的历史命令数量上限；超过后丢弃最旧记录。
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


## 运行时改写 receiver_id；如果已经注册到 CommandService，会先注销旧 id 再用新 id 注册。
func configure_receiver_id(id: String) -> void:
	if id == "":
		return
	if _registered_router != null and receiver_id != id:
		_registered_router.unregister_receiver(receiver_id)
		_registered_router = null
	receiver_id = id
	_register_with_router()


## 接收 GameCommand、记录 history，并优先转发给状态机；状态机未处理时调用 handle_unhandled_command。
## 任一路径处理成功都会 mark_consumed 并返回 true。
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


## 子类覆写的兜底命令处理入口；默认不消费命令。
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
