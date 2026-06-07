class_name InteractionComponent
extends Area2D
signal interactable_focused(interactable: Interactable)
signal interactable_unfocused(interactable: Interactable)
var current_interactable: Interactable = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


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
