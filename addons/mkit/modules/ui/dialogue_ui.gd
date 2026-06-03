class_name DialogueUI
extends Control
var controller: DialogueController = null


func bind(dialogue_controller: DialogueController) -> void:
	controller = dialogue_controller
	if controller != null:
		if not controller.node_entered.is_connected(_on_node_entered):
			controller.node_entered.connect(_on_node_entered)
		if not controller.choices_presented.is_connected(_on_choices_presented):
			controller.choices_presented.connect(_on_choices_presented)
		if not controller.dialogue_ended.is_connected(_on_dialogue_ended):
			controller.dialogue_ended.connect(_on_dialogue_ended)


func _on_node_entered(node: DialogueNode) -> void:
	var speaker := get_node_or_null("SpeakerLabel") as Label
	if speaker != null:
		speaker.text = node.speaker_id
	var text := get_node_or_null("TextLabel") as Label
	if text != null:
		text.text = node.text
	_clear_choices()


func _on_choices_presented(_node: DialogueNode, available: Array[DialogueChoice]) -> void:
	var container := get_node_or_null("ChoiceContainer")
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	for i in available.size():
		var choice := available[i]
		var button := Button.new()
		button.text = choice.text
		var index := i
		button.pressed.connect(func(): controller.choose(index))
		container.add_child(button)


func _on_dialogue_ended(_dialogue_id: String) -> void:
	_clear_choices()
	visible = false


func _clear_choices() -> void:
	var container := get_node_or_null("ChoiceContainer")
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
