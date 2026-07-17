class_name DialogueInteractable
extends Interactable
## 说明：`DialogueInteractable` 是 对话系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在对话系统中复用这段契约或状态时使用它。
## 示例：`var instance := DialogueInteractable.new()`

## 引用的 DialogueDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var dialogue_id: String = ""
## 触发对话的 NPC 或实体 id；用于事件归因和条件判断。
@export var npc_id: String = ""


func _interact_impl(context: GameplayContext) -> bool:
	if dialogue_id == "":
		return false
	var dialogue := Mkit.dialogue()
	if dialogue == null:
		return false
	if not dialogue.start(dialogue_id, context):
		return false
	if npc_id != "":
		var events := Mkit.events()
		if events != null:
			events.emit_domain_event(DialogueEvents.npc_talked(npc_id))
	return true


