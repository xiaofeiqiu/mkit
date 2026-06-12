class_name InteractionComponent
extends Area2D
## 说明：`InteractionComponent` 是 交互系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := InteractionComponent.new()`

## 当 `InteractionComponent` 发生 `interactable focused` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal interactable_focused(interactable: Interactable)
## 当 `InteractionComponent` 发生 `interactable unfocused` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal interactable_unfocused(interactable: Interactable)
## 当前处于可交互范围内的对象；没有目标时为 null。
var current_interactable: Interactable = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


## 执行 `try_interact` 对应的公开操作，并保持 `InteractionComponent` 的领域契约一致。
func try_interact() -> bool:
	if current_interactable == null:
		return false
	var ctx := GameplayContext.from_nodes(owner, current_interactable.owner)
	return current_interactable.interact(ctx)


func _on_area_entered(area: Area2D) -> void:
	var interactable := area.get_node_or_null("Interactable") as Interactable
	if interactable != null:
		current_interactable = interactable
		interactable_focused.emit(interactable)


func _on_area_exited(area: Area2D) -> void:
	var interactable := area.get_node_or_null("Interactable") as Interactable
	if interactable != null and interactable == current_interactable:
		interactable_unfocused.emit(interactable)
		current_interactable = null
