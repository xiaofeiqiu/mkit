extends GutTest


const QUEST_ID := "quest.int.errand"
const OBJ_TALK_ELDER := "obj.talk_elder"
const DIALOGUE_GUIDE_ID := "dlg.int.guide"
const DIALOGUE_ELDER_ID := "dlg.int.elder"
const NPC_GUIDE_ID := "npc.int.guide"
const NPC_ELDER_ID := "npc.int.elder"
const REWARD_CURRENCY_ID := "gold"
const REWARD_AMOUNT := 25
const SAVE_PATH := "/tmp/mkit_dialogue_pipeline_integration_save.json"


func after_each() -> void:
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_dialogue_01_interact_choice_accepts_quest_then_talk_completes() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)

	var dialogue := ServiceRegistry.get_port("dialogue") as DialogueService
	var quest := ServiceRegistry.get_port("quest") as QuestService
	var events := ServiceRegistry.get_port("events") as EventService
	var progression := ServiceRegistry.get_port("progression") as ProgressionService
	assert_not_null(dialogue)
	assert_not_null(quest)
	assert_not_null(events)
	assert_not_null(progression)

	var player := _make_player()
	var interactor := InteractionComponent.new()
	interactor.name = "InteractionComponent"
	player.add_child(interactor)
	interactor.owner = player

	var guide := _make_npc("Guide", NPC_GUIDE_ID, DIALOGUE_GUIDE_ID)
	var elder := _make_npc("Elder", NPC_ELDER_ID, DIALOGUE_ELDER_ID)

	watch_signals(dialogue)
	watch_signals(quest)
	watch_signals(events)
	watch_signals(progression)

	# 1) interact with the guide -> dialogue starts + npc_talked(guide); quest not yet active
	interactor.current_interactable = guide.get_node("Interactable") as DialogueInteractable
	assert_true(interactor.try_interact())
	assert_true(dialogue.is_active())
	assert_signal_emitted_with_parameters(dialogue, "dialogue_started", [DIALOGUE_GUIDE_ID])
	var evt_npc_talked_1 := DomainEventAsserts.last_event(events, "npc_talked")
	assert_not_null(evt_npc_talked_1)
	assert_eq(evt_npc_talked_1.source_id, NPC_GUIDE_ID)
	assert_null(quest.get_state(QUEST_ID))

	# 2) choose the accept option -> AcceptQuestEffect makes the quest active; guide dialogue ends
	dialogue.choose(0)
	assert_false(dialogue.is_active())
	assert_eq(quest.get_state(QUEST_ID).status, "active")
	assert_signal_emitted_with_parameters(quest, "quest_accepted", [QUEST_ID])
	var evt_dialogue_ended_2 := DomainEventAsserts.last_event(events, "dialogue_ended")
	assert_not_null(evt_dialogue_ended_2)
	assert_eq(evt_dialogue_ended_2.source_id, DIALOGUE_GUIDE_ID)

	# 3) interact with the elder -> npc_talked(elder) advances + auto-completes + rewards
	interactor.current_interactable = elder.get_node("Interactable") as DialogueInteractable
	assert_true(interactor.try_interact())
	var evt_npc_talked_3 := DomainEventAsserts.last_event(events, "npc_talked")
	assert_not_null(evt_npc_talked_3)
	assert_eq(evt_npc_talked_3.source_id, NPC_ELDER_ID)
	assert_signal_emitted_with_parameters(
		quest, "objective_advanced", [QUEST_ID, OBJ_TALK_ELDER, 1, 1]
	)
	assert_eq(quest.get_state(QUEST_ID).status, "turned_in")
	assert_signal_emitted_with_parameters(quest, "quest_turned_in", [QUEST_ID])
	assert_eq(progression.get_currency(REWARD_CURRENCY_ID), REWARD_AMOUNT)

	# 4) the elder dialogue is a single linear line; advancing ends it
	assert_true(dialogue.is_active())
	dialogue.advance()
	assert_false(dialogue.is_active())
	var evt_dialogue_ended_4 := DomainEventAsserts.last_event(events, "dialogue_ended")
	assert_not_null(evt_dialogue_ended_4)
	assert_eq(evt_dialogue_ended_4.source_id, DIALOGUE_ELDER_ID)


func _make_database() -> ResourceDatabase:
	var objective := IntTestHelpers.make_quest_objective_definition(
		OBJ_TALK_ELDER, "npc_talked", "npc_id", NPC_ELDER_ID, 1
	)
	var reward := IntTestHelpers.make_grant_currency_effect(
		"fx.int.dlg_reward", REWARD_CURRENCY_ID, REWARD_AMOUNT
	)
	var objectives: Array[QuestObjectiveDefinition] = [objective]
	var rewards: Array[GameEffect] = [reward]
	var quest := IntTestHelpers.make_quest_definition(QUEST_ID, "Elder Errand", objectives, rewards, true)

	var accept := AcceptQuestEffect.new()
	accept.effect_id = "fx.int.accept"
	accept.quest_id = QUEST_ID
	var choice_effects: Array[GameEffect] = [accept]
	var accept_choice := DialogueChoice.new()
	accept_choice.text = "I'll talk to the elder"
	accept_choice.next_node_id = ""
	accept_choice.effects = choice_effects
	var guide_choices: Array[DialogueChoice] = [accept_choice]
	var guide_node := DialogueNode.new()
	guide_node.node_id = "n.offer"
	guide_node.speaker_id = "guide"
	guide_node.text = "Seek the elder in the back room."
	guide_node.choices = guide_choices
	var guide_nodes: Array[DialogueNode] = [guide_node]
	var guide := DialogueDefinition.new()
	guide.dialogue_id = DIALOGUE_GUIDE_ID
	guide.start_node_id = "n.offer"
	guide.nodes = guide_nodes

	var elder_node := DialogueNode.new()
	elder_node.node_id = "n.greet"
	elder_node.speaker_id = "elder"
	elder_node.text = "You came. The village thanks you."
	var elder_nodes: Array[DialogueNode] = [elder_node]
	var elder := DialogueDefinition.new()
	elder.dialogue_id = DIALOGUE_ELDER_ID
	elder.start_node_id = "n.greet"
	elder.nodes = elder_nodes

	var resources: Array[Resource] = [quest, guide, elder]
	return IntTestHelpers.make_resource_database("dialogue_int", resources)


func _make_player() -> Node:
	var player := IntTestHelpers.make_inventory_entity("Player", "player", 10)
	add_child_autofree(player)
	return player


func _make_npc(npc_name: String, npc_id: String, dialogue_id: String) -> Node:
	var npc := Node2D.new()
	npc.name = npc_name
	var interactable := DialogueInteractable.new()
	interactable.name = "Interactable"
	interactable.npc_id = npc_id
	interactable.dialogue_id = dialogue_id
	npc.add_child(interactable)
	interactable.owner = npc
	add_child_autofree(npc)
	return npc
