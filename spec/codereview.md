# Code Review — Scene8 S5 (Enemy AI)

**Scope:** `main` branch vs prior commit (`git diff main~1...HEAD`)
**Effort:** high-recall, 7-angle finder pass + 1-vote verifier per candidate
**Date:** 2026-06-06

```json
[
  {
    "file": "game/demo/entities/player/player_input_reader.gd",
    "line": 57,
    "summary": "Q-key ability cast silently broken in all pre-demo scenes after hardcoded ability_id was replaced with an unset @export",
    "failure_scenario": "Resolved by S11: retired slice scenes were removed, and the village RPG demo remains the only demo entry that overrides cast_ability_id."
  },
  {
    "file": "game/demo/village_rpg/entities/states/enemy_attack_state.gd",
    "line": 25,
    "summary": "Enemy permanently stuck in Attack state when the 'actions' service is unavailable at enter() time",
    "failure_scenario": "If ServiceRegistry.get_service('actions') returns null, the TimedAttackAction is created and connected to _on_action_completed but never started via runner.start_action(). The completed signal never fires, so _on_action_completed never calls request_transition('Enemy/Idle'). The enemy has no other exit path from this state and is locked forever."
  },
  {
    "file": "game/demo/village_rpg/village_rpg_demo.gd",
    "line": 649,
    "summary": "_command_combat_succeeded never set when the scripted fallback strike kills the beast",
    "failure_scenario": "_engage_field_beast_via_commands() sets _command_combat_succeeded = true only when health.dead is true immediately after _attack_field_beast(). When the command chain stalls, it calls _defeat_field_beast() (which may kill the beast) and then returns — _command_combat_succeeded stays false. The auto-loop milestone check at line 1829 then reports 'command_combat' as missing even though combat was completed."
  },
  {
    "file": "game/demo/village_rpg/village_rpg_demo.gd",
    "line": 1527,
    "summary": "_field_beast() relies on the implicit node name 'FieldBeast' that EntitySpawner does not guarantee",
    "failure_scenario": "EntitySpawner.spawn_entity() calls scene.instantiate() and parent.add_child(entity). Godot deduplicates names on add_child, so a second spawn (e.g., after the beast is freed but before the zone refreshes the dedup table) produces 'FieldBeast2'. root.get_node_or_null('FieldBeast') returns null and all subsequent combat checks (_defeat_field_beast, _engage_field_beast_via_commands) silently bail with 'field beast not found'."
  },
  {
    "file": "game/demo/village_rpg/entities/states/enemy_attack_state.gd",
    "line": 39,
    "summary": "handle_command() writes move_direction to the shared blackboard during Attack, polluting subsequent Move state reads",
    "failure_scenario": "Attack state consumes MOVE/STOP_MOVE commands and stores them in blackboard.set_value('move_direction', ...). Attack never reads this key itself. On transition to Enemy/Move, MoveState.physics_update immediately reads 'move_direction' and drives movement before the Brain issues a fresh command (up to think_interval=0.2 s later). A stale ZERO stored by STOP_MOVE causes an instant re-transition to Idle, breaking post-attack repositioning."
  },
  {
    "file": "game/demo/village_rpg/entities/states/enemy_move_state.gd",
    "line": 33,
    "summary": "_move_speed() calls get_node_or_null('Components/StatsComponent') on every physics_update tick",
    "failure_scenario": "get_node_or_null performs a scene-tree path lookup each call. For an entity with a non-trivial subtree this runs every physics frame (60 Hz). Caching the StatsComponent reference in _ready() or on first access would eliminate the repeated lookup at no correctness cost."
  },
  {
    "file": "game/demo/village_rpg/entities/states/enemy_move_state.gd",
    "line": 12,
    "summary": "dir.normalized() called each physics frame on a direction already stored normalized by the Brain",
    "failure_scenario": "SimpleAIEnemyBrain stores direction as (target - owner).normalized() in the blackboard. MoveState reads it and calls .normalized() again unconditionally — a redundant sqrt per frame. The Brain could store the pre-normalized value or MoveState could trust the stored value, not both normalize."
  },
  {
    "file": "addons/mkit/modules/entity/entity_spawner.gd",
    "line": 77,
    "summary": "EntitySpawner encodes the CommandReceiver boot protocol, coupling the spawner to a specific node layout detail",
    "failure_scenario": "_initialize_command_receiver() reaching into 'CommandReceiver' by path and pre-setting receiver_id replicates knowledge that already lives in CommandReceiver._ready(). If CommandReceiver changes its registration timing or id-derivation logic, EntitySpawner must be updated in sync. The correct fix is to expose a configure(id) method on CommandReceiver so the protocol is owned by one class."
  },
  {
    "file": "addons/mkit/modules/ai/brain.gd",
    "line": 8,
    "summary": "Brain.blackboard and StateMachine.blackboard are separate instances sharing overlapping key names with no documented contract",
    "failure_scenario": "Brain writes 'intent', 'distance', 'move_direction', 'facing', 'target' to its own blackboard; States read 'move_direction' and 'facing' from StateMachine.blackboard. A future maintainer writing a state that reads from blackboard (thinking it shares Brain writes) gets stale/default values. The design needs either one shared blackboard or a documented boundary."
  }
]
```
