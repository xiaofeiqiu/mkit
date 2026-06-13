class_name DialogueService
extends Node
## 说明：`DialogueService` 是 对话系统 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(DialogueService.SERVICE_ID, DialogueService.new())`

## 当 `DialogueService` 发生 `dialogue started` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal dialogue_started(dialogue_id: String)
## 当 `DialogueService` 发生 `node entered` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal node_entered(node: DialogueNode)
## 当 `DialogueService` 发生 `choices presented` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal choices_presented(node: DialogueNode, available: Array[DialogueChoice])
## 当 `DialogueService` 发生 `dialogue ended` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal dialogue_ended(dialogue_id: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `DialogueService`。
const SERVICE_ID: String = "dialogue"
## 当前领域运行时对象；服务方法会在创建后复用它。
var runtime: DialogueRuntime = null


## 检查当前对象是否满足 `active` 状态；调用方可据此选择后续流程。
func is_active() -> bool:
	return runtime != null


## 启动对象流程并记录上下文；成功后进入运行中状态并触发生命周期 hook。
func start(dialogue_id: String, context: GameplayContext) -> bool:
	if is_active():
		return false
	var definition := get_definition(dialogue_id)
	if definition == null:
		return false
	var start_node := _resolve_start_node(definition)
	if start_node == null:
		return false
	runtime = DialogueRuntime.new()
	runtime.dialogue_id = dialogue_id
	runtime.context = GameplayContext.from_context(context)
	dialogue_started.emit(dialogue_id)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(DialogueEvents.dialogue_started(dialogue_id))
	_enter_node(start_node.node_id)
	return is_active()


## 读取当前对象中的 `available_choices`；未找到时返回 null、空集合或该 API 的默认值。
func get_available_choices() -> Array[DialogueChoice]:
	var available: Array[DialogueChoice] = []
	var node := _current_node()
	if node == null:
		return available
	for choice in node.choices:
		if choice == null:
			continue
		if ConditionEvaluator.evaluate_all(choice.conditions, runtime.context):
			available.append(choice)
	return available


## 选择指定分支并推进对应流程；返回值、signal 或事件会表达实际执行结果。
func choose(choice_index: int) -> void:
	if runtime == null:
		return
	var available := get_available_choices()
	if choice_index < 0 or choice_index >= available.size():
		return
	var choice := available[choice_index]
	_run_effects(choice.effects)
	if runtime == null:
		return
	if choice.next_node_id == "":
		end()
		return
	_enter_node(choice.next_node_id)


## 推进对应目标或流程进度；返回值、signal 或事件会表达实际执行结果。
func advance() -> void:
	if runtime == null:
		return
	var node := _current_node()
	if node == null:
		end()
		return
	if not node.choices.is_empty():
		return
	if node.next_node_id == "":
		end()
		return
	_enter_node(node.next_node_id)


## 执行 `end` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func end() -> void:
	if runtime == null:
		return
	var ended_id := runtime.dialogue_id
	runtime = null
	dialogue_ended.emit(ended_id)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(DialogueEvents.dialogue_ended(ended_id))


## 读取当前对象中的 `definition`；未找到时返回 null、空集合或该 API 的默认值。
func get_definition(dialogue_id: String) -> DialogueDefinition:
	var content := Mkit.content()
	if content == null:
		return null
	return content.get_resource(dialogue_id) as DialogueDefinition


func _resolve_start_node(definition: DialogueDefinition) -> DialogueNode:
	if definition.start_node_id != "":
		return definition.get_node(definition.start_node_id)
	for node in definition.nodes:
		if node != null:
			return node
	return null


func _enter_node(node_id: String) -> void:
	if runtime == null:
		return
	var definition := get_definition(runtime.dialogue_id)
	if definition == null:
		end()
		return
	var node := definition.get_node(node_id)
	if node == null:
		end()
		return
	runtime.current_node_id = node_id
	runtime.history.append(node_id)
	_run_effects(node.on_enter_effects)
	if runtime == null:
		return
	node_entered.emit(node)
	if not node.choices.is_empty():
		choices_presented.emit(node, get_available_choices())


func _current_node() -> DialogueNode:
	if runtime == null:
		return null
	var definition := get_definition(runtime.dialogue_id)
	if definition == null:
		return null
	return definition.get_node(runtime.current_node_id)


func _run_effects(effects: Array[GameEffect]) -> void:
	if effects.is_empty():
		return
	if runtime == null:
		return
	var executor := Mkit.effects()
	if executor == null:
		return
	executor.execute_many(effects, runtime.context, false)
