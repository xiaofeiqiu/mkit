# Godot RPG / Roguelite Kit 重新设计草案

目标不是做一个功能最多的框架，而是做一个适合教学、容易理解、容易扩展、能复用到 RPG 和 roguelite 项目的 kit。

核心判断：

- 新手应该先学少量稳定概念，而不是一开始面对大型框架。
- 每个系统都应该能用简单例子讲清楚。
- 课程里的每一步都应该能产生可见游戏结果。
- kit 内部可以有专业结构，但对学生暴露的入口必须简单。

## 方案一：Action-Effect Kit

这是最适合 Udemy 课程主线的设计。

核心概念只有五个：

```text
Actor       谁在游戏里行动
Component   Actor 有什么能力
Action      Actor 想做什么
Effect      Action 造成什么结果
Definition  静态配置数据
```

整体流程：

```text
Player / AI
  -> Action
  -> Effect
  -> Component
  -> Event / UI / Audio
```

例子：

```text
Player uses FireballAction
  -> CostManaEffect
  -> DamageEffect
  -> BurnEffect
  -> PlaySoundEffect
```

推荐目录：

```text
addons/coursekit/
  core/
    game.gd
    content.gd
    events.gd
    save.gd
    rng.gd

  actor/
    actor.gd
    components/
      health_component.gd
      stats_component.gd
      inventory_component.gd
      ability_component.gd
      state_machine_component.gd

  action/
    action.gd
    attack_action.gd
    use_item_action.gd
    cast_ability_action.gd
    interact_action.gd

  effect/
    effect.gd
    damage_effect.gd
    heal_effect.gd
    give_item_effect.gd
    spawn_effect.gd
    start_quest_effect.gd

  definition/
    item_def.gd
    ability_def.gd
    enemy_def.gd
    loot_table_def.gd
    quest_def.gd
    room_def.gd
```

FSM 仍然存在，但它只是 Actor 的行为组件：

```text
Actor
  HealthComponent
  StatsComponent
  AbilityComponent
  StateMachineComponent
```

FSM 管这些状态：

```text
Idle
Move
Attack
Cast
Hit
Dead
```

FSM 不直接管理背包、任务、掉落、存档。它只决定 Actor 现在处于什么行为状态，以及这个状态是否要触发 Action。

敌人行为示例：

```text
AI sees player
  -> FSM enters Chase
  -> in range
  -> FSM enters Attack
  -> Attack state triggers AttackAction
  -> AttackAction applies DamageEffect
```

对学生暴露的简单入口：

```gdscript
Game.do_action(player, attack_action, enemy)
Game.apply_effect(enemy, damage_effect)
Game.give_item(player, "potion")
Game.start_quest("first_quest")
```

课程章节可以这样排：

```text
1. 创建 Actor
2. 添加 Health / Stats
3. 做普通攻击
4. 做技能系统
5. 做物品系统
6. 做掉落系统
7. 做任务系统
8. 做 FSM 敌人 AI
9. 做 roguelite 房间和随机掉落
10. 做存档
```

优点：

- 概念少，容易讲。
- 每个概念都有直接游戏效果。
- RPG 和 roguelite 都能复用同一套 Action / Effect。
- 学生容易扩展自己的技能、道具、怪物和掉落。

缺点：

- 大型项目后期可能需要更清晰的模块边界。
- 如果所有内容都堆在同一层，项目变大后需要升级结构。

## 方案二：Module-Service Kit

这是更专业、更适合长期维护的设计。

核心概念：

```text
Game
Module
Service
Actor
Component
Definition
Event
```

每个功能是一个独立模块：

```text
CombatModule
InventoryModule
QuestModule
LootModule
DialogueModule
ShopModule
RogueliteModule
SaveModule
```

每个模块有自己的定义、组件、行为、效果和事件：

```text
modules/combat/
  combat_service.gd
  definitions/
    damage_type_def.gd
    ability_def.gd
  components/
    health_component.gd
    hitbox_component.gd
  actions/
    attack_action.gd
    cast_ability_action.gd
  effects/
    damage_effect.gd
  events/
    damage_event.gd
```

整体目录：

```text
addons/prokit/
  core/
    game.gd
    module.gd
    service_registry.gd
    event_bus.gd
    content_database.gd
    save_service.gd

  actor/
    actor.gd
    component.gd
    state_machine.gd
    state.gd

  modules/
    combat/
    inventory/
    quest/
    loot/
    dialogue/
    shop/
    world/
    roguelite/
```

整体流程：

```text
Input / AI
  -> Actor
  -> Module Action
  -> Module Service
  -> Event
  -> Other Modules
```

例子：

```text
CombatModule emits EnemyKilledEvent
  -> LootModule creates drops
  -> QuestModule updates objective
  -> AudioModule plays sound
  -> UI updates quest tracker
```

新增一个系统时，学生可以照固定模板扩展：

```text
CraftingModule
  crafting_service.gd
  recipe_def.gd
  craft_action.gd
  consume_items_effect.gd
  give_item_effect.gd
```

优点：

- 模块边界清晰。
- 更适合大型 RPG / roguelite。
- 更容易把不同系统拆出来复用。
- 更接近真实项目架构。

缺点：

- 一开始概念更多。
- 不适合作为第一节课就讲的结构。
- 学生可能还没有做出游戏效果，就先被架构压住。

## 推荐方案：教学入口简单，内部结构可升级

最终我会采用混合设计：

```text
新手看到：
  Actor
  Action
  Effect
  Item
  Ability

高级用户看到：
  Module
  Service
  Event
  Save
  ContentDatabase
```

也就是：

```text
课程前半段：Action-Effect Kit
课程后半段：逐步升级到 Module-Service Kit
```

底层可以保留模块化结构，但课程早期不强迫学生理解所有内部服务。学生先通过简单 API 做出攻击、技能、物品、掉落、任务和房间生成，再学习这些系统背后的模块边界。

我会把课程主线设计成：

```text
1. 先做出可玩的 RPG 战斗
2. 把攻击抽象成 Action
3. 把伤害、回血、掉落抽象成 Effect
4. 把角色能力拆成 Component
5. 把技能、物品、怪物变成 Definition
6. 加入 FSM 做敌人行为
7. 加入 Event 连接 UI、音效、任务
8. 加入 Save / RunState 支持 RPG 和 roguelite
9. 把功能整理成 Module
10. 教学生扩展自己的模块
```

这套设计的核心卖点：

```text
一个角色是 Actor
一个能力是 Component
一个行为是 Action
一个结果是 Effect
一个配置是 Definition
一个系统是 Module
```

最终目标是让学生形成一个稳定心智模型：

```text
谁做事？
Actor

做什么？
Action

造成什么结果？
Effect

数据从哪里来？
Definition

状态放在哪里？
Component / Save / RunState

系统怎么扩展？
Module
```

如果只能选一套作为 Udemy 课程的主架构，我会选择方案一 Action-Effect Kit。它最容易讲清楚，也最容易让学生快速做出游戏。

如果课程目标是从入门一路讲到可维护项目，我会在后半段把方案一自然升级成方案二，而不是一开始就上完整 Module-Service 架构。
