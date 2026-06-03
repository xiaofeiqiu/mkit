# Mkit Documentation

## Overview

Mkit 是一个面向 Godot 4.x 的 2D RPG / roguelike 可复用玩法框架。它的目标不是提供固定游戏模板，而是提供一套可以被不同游戏内容复用的 runtime kernel、gameplay modules、platform adapters 和清晰的运行管线。

核心思想：

```text
Game-specific content should be replaceable.
Mkit runtime behavior should be reusable.
Game rules should be data-driven where possible.
Complex gameplay should be composed from small, explicit, testable modules.
```

Mkit 把下面几类职责拆开：

```text
Data definition
Runtime state
Behavior orchestration
Gameplay resolution
Presentation feedback
Platform integration
```

这样可以让具体游戏内容保持可替换，同时让命令、事件、状态机、Action、Effect、战斗、背包、房间、奖励、存档和平台服务保持可测试、可调试、可扩展。

## Architecture Layers

Mkit 的架构按依赖方向分层：

```text
Game Content
  -> Module Layer
  -> Kernel Layer
  -> Platform Adapter Layer
```

依赖只能向下。游戏内容可以使用 module 和 kernel；module 可以使用 kernel；kernel 只依赖更底层的平台接口抽象。Mkit 不应该反向依赖具体玩家、敌人、Boss、房间、物品、剧情、广告经济或商店定价规则。

## Docs Index

- [Module Layer](module_layer.md)：可复用 gameplay domain 模块，例如 entity、combat、stats、ability、inventory、loot、quest、room、run、progression、AI、interaction、UI feedback。
- [Kernel Layer](kernel_layer.md)：runtime foundation，例如 service registry、content registry、command router、event router、HFSM、action runner、condition evaluator、effect executor、save、random、time、object pool、debug。
- [Platform Adapter Layer](platform_adapter_layer.md)：平台能力接口和 mock，例如 ads、IAP、analytics、cloud save。
- [Pipeline](pipeline.md)：完整运行管线索引，覆盖启动、内容注册、命令、事件、HFSM、Action、Effect、战斗、背包、任务、房间、奖励、存档、UI、平台服务和 Debug。

Game Content 属于具体项目内容层，通常放在 `res://game/`。它不是 Mkit 可复用层的一部分，因此这里不维护单独的 layer 文档。

## Runtime Pipeline

核心 runtime 管线：

```text
Input / AI / Script
  -> GameCommand
  -> CommandRouter / CommandReceiver
  -> HFSM
  -> GameAction
  -> GameEffect
  -> Domain System
  -> EventRouter
  -> UI / Audio / VFX / Analytics
```

完整管线索引见 [Pipeline](pipeline.md)。

## Core Data Model

Mkit 推荐把静态配置、运行时实例、节点行为和系统解析拆开：

```text
Definition Resource
  -> Runtime Instance
  -> Controller / Component
  -> System / Resolver
```

例子：

```text
AbilityDefinition  -> AbilityInstance  -> AbilityController
ItemDefinition     -> ItemInstance     -> InventoryController / EquipmentController
StatusDefinition   -> StatusInstance   -> StatusEffectController
RoomDefinition     -> RoomRuntime      -> RoomController / RunDirector
DamageRequest      -> DamageResult     -> CombatResolver / HealthComponent
QuestDefinition    -> QuestState       -> QuestSystem
```

## Class Reference

每个可复用 class 的详细说明在 [ref](ref/) 目录下。Layer 文档会按架构层和 domain 分类链接到对应 class reference。
