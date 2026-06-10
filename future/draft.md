# Godot 4 Action RPG / Roguelite Kit Udemy 课程方案

这个 Udemy 项目是一个独立项目，不依赖当前 mkit 仓库。当前仓库只提供架构讨论经验和上下文参考。

目标不是做一个功能最多的框架，而是做一个适合教学、容易理解、容易扩展、并能复用到 Action RPG 和 roguelite 项目的 Godot kit。

## 核心结论

推荐方向：

```text
一个 kit
一个课程主线
一个简单入口
内部逐步长出专业结构
```

不要做两套并行框架：

```text
不推荐：
addons/coursekit/
addons/prokit/
```

更好的结构是：

```text
推荐：
addons/rpg_kit/
game/
```

课程前半段只让学生看到简单概念：

```text
Actor
Component
Action
Effect
Definition
```

课程后半段再解释高级结构：

```text
Event
Service
Module
Save
RunState
```

## 教学原则

不要采用这两种极端方式：

```text
错误方式 A：
一开始讲完整框架
  -> 学生还没有看到游戏效果
  -> 概念太多
  -> 学生不知道为什么需要这些抽象

错误方式 B：
先写一坨能跑的 demo
  -> 后面大规模重构
  -> 学生觉得前面白学
  -> 抽象过程混乱
```

推荐方式是：

```text
每一章先做出可见玩法
每一章只引入一个必要抽象
旧代码不推翻，只向下一层整理
```

也就是：

```text
不是“先游戏，再抽象”。
而是“先可见玩法，再引入一个必要抽象”。
```

示例节奏：

```text
第 1 次抽象：扣血结果 -> DamageEffect
第 2 次抽象：攻击过程 -> AttackAction
第 3 次抽象：技能配置 -> AbilityDefinition
第 4 次抽象：角色状态 -> Component
第 5 次抽象：跨系统通信 -> Event
第 6 次抽象：系统边界 -> Module / Service
```

这样学生看到的是代码自然长出来，而不是老师突然重写项目。

## 产品定位

课程主卖点应该是 Action RPG kit，roguelite 是高级扩展。

推荐定位：

```text
Build a reusable Godot 4 Action RPG Kit,
then extend it with loot, quests, save/load, and roguelite rooms.
```

不推荐定位：

```text
Build a complete RPG and roguelite framework.
```

原因：

- framework 听起来更专业，但会提高学生预期和课程复杂度。
- RPG 和 roguelite 同时做主线会让范围失控。
- Action RPG 主线更容易展示可见结果：攻击、血条、技能、掉落、任务、存档。
- Roguelite 可以作为后半段扩展：房间、随机掉落、一局状态、临时升级。

## 核心心智模型

学生最终应该记住这套模型：

```text
谁在行动？
Actor

Actor 有什么能力和状态？
Component

Actor 想做什么？
Action

Action 造成什么结果？
Effect

静态数据从哪里来？
Definition

系统之间怎么通知？
Event

功能变大后怎么组织？
Module / Service
```

整体流程：

```text
Player / AI / Script
  -> Action
  -> Effect
  -> Component
  -> Event
  -> UI / Audio / VFX / Quest / Loot / Save
```

示例：

```text
Player uses Fireball
  -> CastAbilityAction
  -> SpawnProjectileEffect
  -> DealDamageEffect
  -> ApplyBurnEffect
  -> Emit damage_applied / enemy_died event
  -> UI, audio, quest, loot respond
```

## 技术架构

只做一个 addon：

```text
addons/rpg_kit/
  core/
    game.gd
    event_bus.gd
    content_database.gd
    rng.gd
    save_service.gd

  actor/
    actor.gd
    actor_component.gd
    components/
      health_component.gd
      stats_component.gd
      inventory_component.gd
      ability_component.gd
      state_machine_component.gd

  action/
    action.gd
    attack_action.gd
    cast_ability_action.gd
    use_item_action.gd
    interact_action.gd

  effect/
    effect.gd
    damage_effect.gd
    heal_effect.gd
    give_item_effect.gd
    spawn_scene_effect.gd
    start_quest_effect.gd

  definition/
    item_definition.gd
    ability_definition.gd
    enemy_definition.gd
    loot_table_definition.gd
    quest_definition.gd
    room_definition.gd

  modules/
    combat/
    inventory/
    loot/
    quest/
    save/
    world/
    roguelite/
```

游戏内容放在项目自己的 `game/` 目录：

```text
game/
  actors/
  abilities/
  items/
  enemies/
  quests/
  rooms/
  ui/
  scenes/
```

原则：

- `addons/rpg_kit/` 只放可复用机制。
- `game/` 放具体玩家、怪物、技能、道具、地图、任务、数值。
- 课程代码应该能被学生迁移到自己的项目，而不是只为 demo 服务。

## Godot 教学体验

Godot 课程不能只靠代码。学生需要看到 Inspector 和 Resource 的价值。

必须设计这些 `.tres` 资产：

```text
AbilityDefinition.tres
ItemDefinition.tres
EnemyDefinition.tres
LootTableDefinition.tres
QuestDefinition.tres
RoomDefinition.tres
```

课程里应该反复强调：

```text
代码定义规则
Resource 配置内容
Scene 组合对象
Signal / Event 连接反馈
```

这样学生不只是学 GDScript，也会学到 Godot 的真实生产方式。

## Action / Effect / Component 边界

必须把边界讲死，否则后面会混乱。

### Action

Action 表示一个行为过程。

它可以有：

```text
持续时间
动画
冷却
取消
目标
范围
输入来源
```

例子：

```text
AttackAction
CastAbilityAction
UseItemAction
InteractAction
DashAction
```

### Effect

Effect 表示一个结果。

它应该尽量短、明确、可组合：

```text
DamageEffect
HealEffect
GiveItemEffect
SpawnSceneEffect
StartQuestEffect
ApplyStatusEffect
```

Effect 不应该管理长时间行为。长时间行为属于 Action、State 或 Component。

### Component

Component 持有 Actor 的状态和局部规则：

```text
HealthComponent
StatsComponent
InventoryComponent
AbilityComponent
StateMachineComponent
```

Component 不应该知道整个游戏流程，也不应该直接管理任务、掉落、存档。

### Definition

Definition 是静态配置数据，通常是 Godot Resource：

```text
AbilityDefinition
ItemDefinition
EnemyDefinition
LootTableDefinition
QuestDefinition
RoomDefinition
```

学生应该通过 Inspector 创建和修改 Definition。

### Event

Event 用来连接系统，不负责业务本身。

例子：

```text
damage_applied
enemy_died
item_picked_up
quest_started
quest_completed
room_cleared
run_started
run_finished
```

UI、音效、VFX、任务、掉落可以监听事件，但不要让攻击代码直接调用所有这些系统。

## FSM 的位置

FSM 仍然存在，但它只是 Actor 的行为组件。

```text
Actor
  HealthComponent
  StatsComponent
  AbilityComponent
  StateMachineComponent
```

FSM 管这些行为状态：

```text
Idle
Move
Chase
Attack
Cast
Hit
Dead
```

FSM 不直接管理背包、任务、掉落、存档。它只决定 Actor 当前处于什么行为状态，以及这个状态是否触发 Action。

敌人行为示例：

```text
AI sees player
  -> FSM enters Chase
  -> target in range
  -> FSM enters Attack
  -> Attack state triggers AttackAction
  -> AttackAction applies DamageEffect
```

## 学生入口 API

课程早期可以提供一个简单 facade，让学生少接触内部服务：

```gdscript
Game.do_action(player, attack_action, enemy)
Game.apply_effect(player, enemy, damage_effect)
Game.give_item(player, "potion")
Game.start_quest(player, "first_quest")
Game.spawn_enemy("slime", spawn_position)
```

后半段再解释这些 API 背后调用了哪些模块：

```text
Game.do_action
  -> ActionRunner
  -> Action
  -> EffectRunner
  -> EventBus
```

这能降低早期认知负担，同时不牺牲后期架构教学。

## 课程结构

推荐三段式。

### Part 1：Build The Game Loop

目标：快速看到可玩的 Action RPG 结果，但代码从第一天就预留边界。

```text
1. Player, enemy, camera, simple arena
   可见结果：玩家能移动，敌人在场景里
   新概念：Actor

2. Health bar and death
   可见结果：敌人能掉血、死亡
   新概念：HealthComponent

3. Basic attack
   可见结果：玩家能攻击敌人
   新概念：DamageEffect

4. Attack timing and animation
   可见结果：攻击有前摇、命中时机、动画
   新概念：AttackAction

5. Enemy chase and attack
   可见结果：敌人会追击并攻击玩家
   新概念：StateMachineComponent
```

### Part 2：Turn The Game Into A Kit

目标：把已经能玩的功能整理成可复用系统。

```text
6. Ability system
   可见结果：玩家能释放火球或治疗
   新概念：AbilityDefinition

7. Item and inventory
   可见结果：玩家能捡药水、使用药水
   新概念：ItemDefinition / InventoryComponent

8. Loot table
   可见结果：敌人死亡后随机掉落
   新概念：LootTableDefinition

9. Quest basics
   可见结果：击杀敌人推进任务
   新概念：EventBus

10. UI, audio, VFX feedback
    可见结果：伤害数字、音效、命中特效
    新概念：事件驱动反馈
```

### Part 3：Extend The Kit

目标：加入可维护项目需要的系统，并展示如何扩展。

```text
11. Save and load
    可见结果：玩家血量、背包、任务进度能保存
    新概念：SaveService

12. Room definitions
    可见结果：切换或生成战斗房间
    新概念：RoomDefinition

13. Roguelite run state
    可见结果：开始一局、清房间、获得临时奖励
    新概念：RunState

14. Module organization
    可见结果：Combat / Inventory / Quest / Loot 分目录清晰
    新概念：Module / Service

15. Final project: Crafting module
    可见结果：消耗材料制作物品
    新概念：自定义模块扩展
```

## 防止学生混乱的规则

1. 每章只引入一个新抽象。
2. 每个抽象必须先有游戏问题，再给名字。
3. 不做大规模推翻式重构。
4. 不在早期暴露完整服务层。
5. 不让学生同时学习 Action、Effect、Component、Definition、Event。
6. 每章结束时项目必须能运行。
7. 每章都要有一个可见结果。
8. 课程代码里的 demo 内容和 kit 代码必须分目录。

## 需要避免的技术坑

1. Effect 太万能

如果 Effect 既做时间流程、又播动画、又改状态、又发事件，就会失去边界。

处理方式：

```text
Action 管过程
Effect 管结果
Component 管状态
Event 管通知
```

2. Service 太早出现

早期只讲 `Game.do_action()`，不要让学生直接面对 `CombatService`、`QuestService`、`SaveService`。

3. Definition 太抽象

不要第一节课就讲 ResourceDatabase。先让学生做一个 `AbilityDefinition.tres`，看到 Inspector 改数值能改变技能，再讲为什么 Definition 有用。

4. Roguelite 范围过大

Roguelite 只做课程需要的最小闭环：

```text
RoomDefinition
RunState
random reward
temporary upgrade
run end
```

不要在主课里做完整地图生成、复杂词条、meta progression 和商店经济。

5. 课程项目变成工具开发课

可以做 kit，但不要把重心放在编辑器插件、复杂导入器、可视化节点编辑器。Udemy 学生更需要可玩的结果和可迁移代码。

## 最终建议

这门课应该采用：

```text
技术上：
一个 Godot addon
Action / Effect 为主线
Resource Definition 做配置
Event 连接反馈和跨系统
Module / Service 作为后半段组织方式

教学上：
每章一个可见玩法
每章一个必要抽象
不先讲完整架构
不先写混乱 demo 再推翻

产品上：
主打 Action RPG Kit
Roguelite 作为高级扩展
不要把课程包装成完整 framework
```

推荐课程名：

```text
Godot 4 Action RPG Kit:
Build Skills, Items, Quests, Loot, Save, and Roguelite Rooms
```

一句话总结：

```text
先让学生看到游戏结果，再给这个结果一个清晰、必要、可复用的抽象名字。
```
