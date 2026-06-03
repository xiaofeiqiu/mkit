class_name QuestDefinition
extends Resource
@export var quest_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var quest_type: String = "side"
@export var objectives: Array[QuestObjectiveDefinition] = []
@export var prerequisite_quest_ids: Array[String] = []
@export var accept_conditions: Array[Condition] = []
@export var reward_effects: Array[GameEffect] = []
@export var auto_complete: bool = false
@export var repeatable: bool = false
@export var tags: Array[String] = []


func get_resource_id() -> String:
	return quest_id


func get_objective(objective_id: String) -> QuestObjectiveDefinition:
	for objective in objectives:
		if objective != null and objective.objective_id == objective_id:
			return objective
	return null
