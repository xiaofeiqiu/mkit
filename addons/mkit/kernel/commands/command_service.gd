class_name CommandService
extends Node
## 说明：`CommandService` 是可选的命令路由服务，用 `GameCommand.target_id` 找到已注册的 `CommandReceiver`。
## 上游：通常由只知道目标实体 id 的输入、AI、剧情脚本、Mkit 门面或其他领域服务调用。
## 下游：只负责把命令转交给目标 `CommandReceiver`，不直接依赖具体游戏内容。
## 使用：当调用方没有目标节点引用、只能按 `target_id` 发命令时使用；已持有实体或接收器时直接调用 `CommandReceiver.receive_command()`。
## 示例：`ServiceRegistry.register_service(CommandService.SERVICE_ID, CommandService.new())`

## 当 `CommandService` 发生 `command dispatched` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal command_dispatched(command: GameCommand)
## 当 `CommandService` 发生 `command failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal command_failed(command: GameCommand, reason: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `CommandService`。
const SERVICE_ID: String = "commands"
var _receivers: Dictionary = {}


## 注册 `receiver`，让后续查询或路由可以找到它，并保持 `CommandService` 的领域契约一致。
func register_receiver(receiver_id: String, receiver: CommandReceiver) -> void:
	if receiver_id.strip_edges() == "":
		push_warning("CommandService.register_receiver: receiver_id is empty")
		return
	if receiver == null:
		push_error("CommandService.register_receiver: receiver is null for id %s" % receiver_id)
		return
	_receivers[receiver_id] = receiver


## 注销 `receiver`，停止后续查询或路由使用它，并保持 `CommandService` 的领域契约一致。
func unregister_receiver(receiver_id: String) -> void:
	_receivers.erase(receiver_id)


## 把命令或事件分发到目标接收者，并保持 `CommandService` 的领域契约一致。
func dispatch(command: GameCommand) -> bool:
	if command == null:
		push_warning("CommandService.dispatch: command is null")
		return false
	command_dispatched.emit(command)
	if command.consumed:
		command_failed.emit(command, "Command already consumed")
		return false
	if command.target_id.strip_edges() == "":
		command_failed.emit(command, "Missing target_id")
		return false
	if not _receivers.has(command.target_id):
		command_failed.emit(command, "No receiver for target_id: %s" % command.target_id)
		return false
	var receiver := _receivers[command.target_id] as CommandReceiver
	if receiver == null or not is_instance_valid(receiver):
		command_failed.emit(command, "Receiver is invalid for target_id: %s" % command.target_id)
		return false
	var handled := receiver.receive_command(command)
	if not handled:
		command_failed.emit(command, "Receiver did not handle command: %s" % command.command_type)
	return handled
