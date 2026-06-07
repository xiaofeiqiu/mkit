# Claude Code Prompt: MKit Rename Rules

Refactor the project using these rename rules only.

## Naming Convention

```text
Everything registered in ServiceRegistry -> XxxService
```

## Class Rename Rules

Rename every class that is registered in `ServiceRegistry` to use the `XxxService` suffix.

| Current | New |
|---|---|
| `EventRouter` | `EventService` |
| `CommandRouter` | `CommandService` |
| `SceneRouter` | `SceneService` |
| `SaveManager` | `SaveService` |
| `AudioManager` | `AudioService` |
| `ActionRunner` | `ActionService` |
| `EffectExecutor` | `EffectService` |
| `CombatResolver` | `CombatService` |
| `ContentRegistry` | `ContentService` |
| `ObjectPool` | `PoolService` |
| `QuestSystem` | `QuestService` |
| `ProgressionSystem` | `ProgressionService` |
| `ShopController` | `ShopService` |
| `DialogueController` | `DialogueService` |
| `WorldRouter` | `WorldService` |

Classes already using the `XxxService` suffix — no change:

```text
RandomService, TimeService, AnalyticsService, AdService, IAPService, CloudSaveService
```

### Do NOT rename

Classes that are never registered in `ServiceRegistry`:

```text
AbilityController      -> stays AbilityController
InventoryController    -> stays InventoryController
EquipmentController    -> stays EquipmentController
StatusEffectController -> stays StatusEffectController
RoomController         -> stays RoomController
LootSystem             -> stays LootSystem
RewardSystem           -> stays RewardSystem
```

## File Rename Rules

Rename matching script files to match the new class names.

Use:

```text
class_name: PascalCase
file name: snake_case.gd
```

| Current file | New file |
|---|---|
| `event_router.gd` | `event_service.gd` |
| `command_router.gd` | `command_service.gd` |
| `scene_router.gd` | `scene_service.gd` |
| `save_manager.gd` | `save_service.gd` |
| `audio_manager.gd` | `audio_service.gd` |
| `action_runner.gd` | `action_service.gd` |
| `effect_executor.gd` | `effect_service.gd` |
| `combat_resolver.gd` | `combat_service.gd` |
| `content_registry.gd` | `content_service.gd` |
| `object_pool.gd` | `pool_service.gd` |
| `quest_system.gd` | `quest_service.gd` |
| `progression_system.gd` | `progression_service.gd` |
| `shop_controller.gd` | `shop_service.gd` |
| `dialogue_controller.gd` | `dialogue_service.gd` |
| `world_router.gd` | `world_service.gd` |

## Registry Key Rule

Do not rename `ServiceRegistry` keys.

```gdscript
ServiceRegistry.register_service("events", EventService.new())
ServiceRegistry.register_service("quest", QuestService.new())
```

Do not change keys like:

```text
events -> event_service
quest  -> quest_service
```
