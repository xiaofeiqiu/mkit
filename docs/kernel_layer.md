# Kernel Layer

## Layer Level

Kernel Layer 位于 Module Layer 之下，是 Mkit 的 reusable runtime foundation。它定义跨模块共享的生命周期、服务注册、内容注册、命令、事件、HFSM、action、condition、effect、context、save、random、time、pool 和 debug 基础设施。

这个 layer 不应该依赖 Module Layer 或 Game Content Layer。Kernel 的职责是提供通用运行时机制，而不是理解具体 combat、inventory、room 或 player 规则。

## Scope

- Source scope: `res://addons/mkit/kernel/`
- Responsibility: runtime primitives, orchestration, routing, evaluation/execution pipeline, save framework, diagnostics.
- Expected stability: high. Kernel API 应尽量稳定，因为上层模块和游戏内容都会依赖它。

## Classes

- [ActionContext](ref/ActionContext.md)
- [ActionRunner](ref/ActionRunner.md)
- [ApplyStatModifierEffect](ref/ApplyStatModifierEffect.md)
- [ApplyStatusEffect](ref/ApplyStatusEffect.md)
- [Blackboard](ref/Blackboard.md)
- [BuiltinCommands](ref/BuiltinCommands.md)
- [CastAction](ref/CastAction.md)
- [CommandReceiver](ref/CommandReceiver.md)
- [CommandRouter](ref/CommandRouter.md)
- [Condition](ref/Condition.md)
- [ConditionEvaluator](ref/ConditionEvaluator.md)
- [ContentRegistry](ref/ContentRegistry.md)
- [ContentValidationResult](ref/ContentValidationResult.md)
- [CooldownReadyCondition](ref/CooldownReadyCondition.md)
- [DashAction](ref/DashAction.md)
- [DealDamageEffect](ref/DealDamageEffect.md)
- [DebugOverlay](ref/DebugOverlay.md)
- [DomainEvent](ref/DomainEvent.md)
- [EffectExecutor](ref/EffectExecutor.md)
- [EffectResult](ref/EffectResult.md)
- [EventRouter](ref/EventRouter.md)
- [GameAction](ref/GameAction.md)
- [GameBootstrap](ref/GameBootstrap.md)
- [GameCommand](ref/GameCommand.md)
- [GameEffect](ref/GameEffect.md)
- [GameplayContext](ref/GameplayContext.md)
- [GrantItemEffect](ref/GrantItemEffect.md)
- [HealEffect](ref/HealEffect.md)
- [LogEffect](ref/LogEffect.md)
- [ObjectPool](ref/ObjectPool.md)
- [RandomService](ref/RandomService.md)
- [ResourceDatabase](ref/ResourceDatabase.md)
- [SaveManager](ref/SaveManager.md)
- [SaveMigration](ref/SaveMigration.md)
- [Saveable](ref/Saveable.md)
- [SceneRouter](ref/SceneRouter.md)
- [ServiceRegistry](ref/ServiceRegistry.md)
- [SpawnSceneEffect](ref/SpawnSceneEffect.md)
- [State](ref/State.md)
- [StateMachine](ref/StateMachine.md)
- [TargetInRangeCondition](ref/TargetInRangeCondition.md)
- [TimeService](ref/TimeService.md)
- [TimedAttackAction](ref/TimedAttackAction.md)
