class_name DialogueRuntime
extends RefCounted
var dialogue_id: String = ""
var current_node_id: String = ""
var history: Array[String] = []
var context: GameplayContext = null
