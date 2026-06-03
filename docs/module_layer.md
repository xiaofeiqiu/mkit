# Module Layer

## Layer Level

Module Layer 位于 Game Content Layer 之下、Kernel Layer 之上。它提供可复用的 gameplay domain 模块，例如 entity、combat、stats、ability、inventory、room、loot、progression、AI、interaction 和 UI feedback。

这个 layer 可以依赖 Kernel Layer 的命令、事件、上下文、状态机、action、condition、effect、registry、save 等基础能力；它不应该依赖任何具体游戏内容。

## Scope

- Source scope: `res://addons/mkit/modules/`
- Responsibility: reusable gameplay systems, components, controllers, runtime data objects, domain definitions.
- Expected stability: medium. 模块 API 应保持可复用，但会随着 gameplay domain 扩展。

## Classes

### Entity & Composition

- [EntityDefinition](ref/EntityDefinition.md)
- [EntityIdentity](ref/EntityIdentity.md)
- [EntityRoot](ref/EntityRoot.md)
- [EntitySpawner](ref/EntitySpawner.md)

### Stats & Resources

- [ResourcePoolComponent](ref/ResourcePoolComponent.md)
- [StatDefinition](ref/StatDefinition.md)
- [StatModifier](ref/StatModifier.md)
- [StatModifierDefinition](ref/StatModifierDefinition.md)
- [StatsComponent](ref/StatsComponent.md)

### Health & Combat

- [CombatResolver](ref/CombatResolver.md)
- [DamageRequest](ref/DamageRequest.md)
- [DamageResult](ref/DamageResult.md)
- [HealthComponent](ref/HealthComponent.md)
- [HitboxComponent](ref/HitboxComponent.md)
- [HurtboxComponent](ref/HurtboxComponent.md)

### Ability & Status Effects

- [AbilityController](ref/AbilityController.md)
- [AbilityDefinition](ref/AbilityDefinition.md)
- [AbilityInstance](ref/AbilityInstance.md)
- [StatusEffectController](ref/StatusEffectController.md)
- [StatusEffectDefinition](ref/StatusEffectDefinition.md)
- [StatusEffectInstance](ref/StatusEffectInstance.md)

### Inventory & Equipment

- [EquipmentController](ref/EquipmentController.md)
- [InventoryController](ref/InventoryController.md)
- [InventoryModel](ref/InventoryModel.md)
- [InventorySlot](ref/InventorySlot.md)
- [ItemDefinition](ref/ItemDefinition.md)
- [ItemInstance](ref/ItemInstance.md)

### Loot & Rewards

- [LootEntry](ref/LootEntry.md)
- [LootRollResult](ref/LootRollResult.md)
- [LootSystem](ref/LootSystem.md)
- [LootTableDefinition](ref/LootTableDefinition.md)
- [RewardDefinition](ref/RewardDefinition.md)
- [RewardOption](ref/RewardOption.md)
- [RewardSystem](ref/RewardSystem.md)

### Quest

- [AcceptQuestEffect](ref/AcceptQuestEffect.md)
- [AdvanceObjectiveEffect](ref/AdvanceObjectiveEffect.md)
- [CompleteQuestEffect](ref/CompleteQuestEffect.md)
- [QuestDefinition](ref/QuestDefinition.md)
- [QuestLog](ref/QuestLog.md)
- [QuestObjectiveDefinition](ref/QuestObjectiveDefinition.md)
- [QuestState](ref/QuestState.md)
- [QuestSystem](ref/QuestSystem.md)

### Dialogue

- [DialogueChoice](ref/DialogueChoice.md)
- [DialogueController](ref/DialogueController.md)
- [DialogueDefinition](ref/DialogueDefinition.md)
- [DialogueInteractable](ref/DialogueInteractable.md)
- [DialogueNode](ref/DialogueNode.md)
- [DialogueRuntime](ref/DialogueRuntime.md)

### Shop

- [ShopController](ref/ShopController.md)
- [ShopDefinition](ref/ShopDefinition.md)
- [ShopEntry](ref/ShopEntry.md)

### World

- [Portal](ref/Portal.md)
- [SpawnPoint](ref/SpawnPoint.md)
- [WorldRouter](ref/WorldRouter.md)
- [ZoneDefinition](ref/ZoneDefinition.md)

### Room, Run & Generation

- [DungeonGenerator](ref/DungeonGenerator.md)
- [RoomController](ref/RoomController.md)
- [RoomDefinition](ref/RoomDefinition.md)
- [RoomGraph](ref/RoomGraph.md)
- [RoomNode](ref/RoomNode.md)
- [RoomRuntime](ref/RoomRuntime.md)
- [RunDirector](ref/RunDirector.md)
- [RunState](ref/RunState.md)

### Progression

- [ExperienceComponent](ref/ExperienceComponent.md)
- [ExperienceCurve](ref/ExperienceCurve.md)
- [ProgressionState](ref/ProgressionState.md)
- [ProgressionSystem](ref/ProgressionSystem.md)
- [UpgradeDefinition](ref/UpgradeDefinition.md)

### AI & Interaction

- [Brain](ref/Brain.md)
- [Interactable](ref/Interactable.md)
- [InteractionComponent](ref/InteractionComponent.md)
- [SimpleAIEnemyBrain](ref/SimpleAIEnemyBrain.md)

### UI & Feedback

- [AudioManager](ref/AudioManager.md)
- [DamageNumberSystem](ref/DamageNumberSystem.md)
- [DialogueUI](ref/DialogueUI.md)
- [FeedbackSystem](ref/FeedbackSystem.md)
- [QuestLogUI](ref/QuestLogUI.md)
- [RewardSelectionUI](ref/RewardSelectionUI.md)
- [ShopUI](ref/ShopUI.md)
- [UIManager](ref/UIManager.md)
- [VFXSpawner](ref/VFXSpawner.md)
