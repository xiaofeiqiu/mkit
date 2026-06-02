# Mkit Unit Test Spec — GUT

All tests use the [GUT](https://github.com/bitwes/Gut) (Godot Unit Test) framework.

## File layout

```
test/
  unit/
    kernel/
      test_service_registry.gd
      test_command_router.gd
      test_command_receiver.gd
      test_event_router.gd
      test_effect_executor.gd
      test_action_runner.gd
      test_state_machine.gd
    modules/
      test_combat_resolver.gd
      test_ability_controller.gd
      test_inventory_controller.gd
      test_loot_system.gd
      test_progression_system.gd
      test_reward_system.gd
      test_entity_spawner.gd
      test_room_controller.gd
      test_run_director.gd
```

## GUT conventions used

| Convention | Detail |
|---|---|
| Base class | `extends GutTest` |
| Setup | `before_each()` — create fresh instances, clear ServiceRegistry |
| Teardown | `after_each()` — free any added nodes, call `ServiceRegistry.clear()` |
| Assertion style | `assert_eq`, `assert_true`, `assert_false`, `assert_null`, `assert_not_null`, `watch_signals` / `assert_signal_emitted` |
| Mock nodes | Inline `Node` subclasses (inner classes) rather than GUT doubles, to stay compatible with typed GDScript |
| Determinism | Inject a seeded `RandomService` stub before tests that touch `randf()` |

## Progress

| Done | File | System under test | Test file |
|---|---|---|---|
| ✅ | [test_service_registry.md](test_service_registry.md) | `ServiceRegistry` | `test/unit/kernel/test_service_registry.gd` |
| ✅ | [test_command_router.md](test_command_router.md) | `CommandRouter` + `CommandReceiver` | `test/unit/kernel/test_command_router.gd` |
| ✅ | [test_event_router.md](test_event_router.md) | `EventRouter` | `test/unit/kernel/test_event_router.gd` |
| ✅ | [test_effect_executor.md](test_effect_executor.md) | `EffectExecutor` + builtin effects | `test/unit/kernel/test_effect_executor.gd` |
| ✅ | [test_action_runner.md](test_action_runner.md) | `ActionRunner` + `GameAction` | `test/unit/kernel/test_action_runner.gd` |
| ✅ | [test_state_machine.md](test_state_machine.md) | `StateMachine` + `State` | `test/unit/kernel/test_state_machine.gd` |
| ✅ | [test_combat_resolver.md](test_combat_resolver.md) | `CombatResolver` | `test/unit/modules/test_combat_resolver.gd` |
| ✅ | [test_ability_controller.md](test_ability_controller.md) | `AbilityController` | `test/unit/modules/test_ability_controller.gd` |
| ✅ | [test_inventory_controller.md](test_inventory_controller.md) | `InventoryController` | `test/unit/modules/test_inventory_controller.gd` |
| ✅ | [test_loot_system.md](test_loot_system.md) | `LootSystem` | `test/unit/modules/test_loot_system.gd` |
| ✅ | [test_reward_system.md](test_reward_system.md) | `RewardSystem` | `test/unit/modules/test_reward_system.gd` |
| ✅ | [test_entity_spawner.md](test_entity_spawner.md) | `EntitySpawner` | `test/unit/modules/test_entity_spawner.gd` |
| ✅ | [test_room_controller.md](test_room_controller.md) | `RoomController` | `test/unit/modules/test_room_controller.gd` |
| ✅ | [test_run_director.md](test_run_director.md) | `RunDirector` | `test/unit/modules/test_run_director.gd` |
| ✅ | [test_progression_system.md](test_progression_system.md) | `ProgressionSystem` | `test/unit/modules/test_progression_system.gd` |
