# Core Flows, MVP Plan, Debug, and Agent Instructions

---

# 23. 核心流程伪代码

---

## 23.1 玩家攻击流程

### 概念说明

- 是什么：玩家按下攻击键后，从输入到敌人扣血再到反馈播放的完整链路。
- 负责什么：串联 InputReader、GameCommand、CommandReceiver、HFSM、TimedAttackAction、Hitbox/Hurtbox、CombatResolver、HealthComponent 和 FeedbackSystem。
- 为什么需要：这是验证 Mkit 核心管线是否成立的第一条 vertical slice。
```text
InputReader._physics_process
  if Input.is_action_just_pressed("attack"):
      cmd = GameCommand.create("attack", player_id, player_id, {direction, target})
      CommandRouter.dispatch(cmd)

CommandRouter.dispatch
  find Player CommandReceiver
  receiver.receive_command(cmd)

CommandReceiver.receive_command
  state_machine.handle_command(cmd)

PlayerIdleState.handle_command
  if attack:
      transition_to("Player/Alive/Combat/BasicAttack", {command})

BasicAttackState.enter
  create TimedAttackAction
  ActionRunner.start_action(action, context)

TimedAttackAction.update
  startup -> hitbox off
  active -> hitbox on
  recovery -> hitbox off
  complete -> emit completed

HitboxComponent.area_entered
  create DamageRequest
  CombatResolver.resolve
  HealthComponent.apply_damage
  EventRouter.emit_damage_applied

HealthComponent.apply_damage
  hp -= final_amount
  if hp <= 0:
      die
      EventRouter.emit_entity_died

FeedbackSystem
  listens damage_applied / entity_died
  spawn vfx, sound, damage number
```

---

## 23.2 技能释放流程

### 概念说明

- 是什么：一次技能从命令发出到冷却开始的完整链路。
- 负责什么：检查当前状态、技能条件、消耗、冷却、施法 Action、Effect 执行和 UI 冷却显示。
- 为什么需要：技能系统会复用 Condition、Action、Effect、Combat 和 UI；它能检验多个核心系统是否真正解耦。
```text
InputReader detects ability button
  -> CastAbilityCommand ability_id="ability.fireball_basic"

HFSM checks current behavior state
  -> if can cast, transition to CastAbility

CastAbilityState.enter
  -> AbilityController.cast(ability_id, context)

AbilityController.cast
  -> check registered
  -> check enabled
  -> check cooldown
  -> check cost
  -> check conditions
  -> pay cost
  -> if cast_time > 0: start CastAction
  -> else execute effects immediately
  -> start cooldown
  -> emit ability_cast_finished

EffectExecutor
  -> SpawnSceneEffect or DealDamageEffect or ApplyStatusEffect

UI
  -> listens cooldown_started and updates HUD
```

---

## 23.3 房间清理奖励流程

### 概念说明

- 是什么：清光房间敌人后生成奖励、展示选择并推进 Run 的流程。
- 负责什么：串联 Enemy death、RoomController、RunDirector、RewardSystem、RewardSelectionUI 和奖励 Effect 应用。
- 为什么需要：这是 roguelike 循环的心脏：战斗 -> 奖励 -> 下一房间。
```text
Enemy HealthComponent.die
  -> EventRouter.entity_died(entity_id, enemy)

RoomController._on_entity_died
  -> remove from active_enemies
  -> if active_enemies empty:
        runtime.cleared = true
        emit room_cleared
        generate_reward()

RoomController.generate_reward
  -> RewardSystem.generate_options(reward_pool_ids, 3, context)
  -> emit reward_ready(options)

RunDirector.on_room_cleared
  -> status = choosing_reward
  -> UIManager.open_screen("reward_selection", {options, run_director}, true)

RewardSelectionUI
  -> player clicks option
  -> RunDirector.select_reward(option)

RunDirector.select_reward
  -> RewardSystem.apply_selected(option, context)
  -> append reward_history
  -> current_room_index += 1
  -> enter_next_room()
```

---

## 23.4 拾取物品流程

### 概念说明

- 是什么：玩家碰到掉落物后把物品放入背包的流程。
- 负责什么：检测拾取、创建收集请求、校验背包容量/堆叠规则、添加 ItemInstance 并发 inventory_changed 事件。
- 为什么需要：掉落、背包、UI、音效和存档都依赖这条链路。
```text
Pickup Area2D overlaps Player
  -> create ItemInstance
  -> player.InventoryController.can_add_item(item)
  -> InventoryController.add_item(item)
  -> EventRouter.item_collected + inventory_changed
  -> FeedbackSystem plays pickup sound
  -> InventoryUI refreshes view model
```

---

---

# 24. MVP Vertical Slice 实现顺序

---

## Phase 0: Kernel Prototype

### 概念说明

- 是什么：只实现 Mkit 最小运行时内核的阶段。
- 负责什么：完成 ServiceRegistry、EventRouter、ContentRegistry、Command、HFSM、Action、Condition、Effect、Context 和 Debug trace 的雏形。
- 为什么需要：先证明“命令 -> 状态 -> 动作 -> 效果 -> 事件”能跑，再加战斗和背包才不会把地基写歪。
```text
ServiceRegistry
EventRouter
GameCommand
CommandRouter
CommandReceiver
GameplayContext
State
StateMachine
GameAction
ActionRunner
Condition
GameEffect
EffectExecutor
ContentRegistry
RandomService
TimeService
SceneRouter
ObjectPool
```

验证：

```text
DummyEntity receives attack command
State changes Idle -> Attack
Action starts and completes
Effect prints debug result
DebugOverlay shows current state
```

---

## Phase 1: Combat Slice

### 概念说明

- 是什么：第一个可玩的战斗 vertical slice。
- 负责什么：实现玩家移动/攻击、敌人受击、伤害结算、HP 变化、死亡事件和基础反馈。
- 为什么需要：战斗是动作 RPG/roguelike 最核心的循环，先跑通它才能验证架构不是纸上谈兵。
```text
EntityIdentity
StatsComponent
HealthComponent
ResourcePoolComponent
DamageRequest
DamageResult
CombatResolver
HitboxComponent
HurtboxComponent
TimedAttackAction
Basic Player HFSM
Basic Enemy scene
FeedbackSystem minimal log
AudioManager / VFXSpawner / DamageNumberSystem stub
```

验证：

```text
Player moves
Player attacks
Enemy HP decreases
Enemy dies
entity_died event emitted
```

---

## Phase 2: Ability / Status Slice

### 概念说明

- 是什么：技能和状态效果的 vertical slice。
- 负责什么：实现 AbilityDefinition/Instance/Controller、CastAbilityCommand、Projectile/Effect、Cooldown UI 和 Burn/Poison 等状态。
- 为什么需要：技能和状态会同时压测 Condition、Action、Effect、Combat、Stats、UI 多个模块。
```text
AbilityDefinition
AbilityInstance
AbilityController
CastAbilityState
CastAction
SpawnSceneEffect
DealDamageEffect
ApplyStatusEffect
StatusEffectDefinition
StatusEffectController
Burn status
Cooldown UI log
```

验证：

```text
Player casts fireball
Fireball damages enemy
Burn ticks every second
Cooldown blocks repeated cast
```

---

## Phase 3: Inventory / Equipment Slice

### 概念说明

- 是什么：物品、背包和装备的 vertical slice。
- 负责什么：实现 ItemDefinition/Instance、InventoryModel/Controller、EquipmentController、StatModifier、拾取和简单背包 UI。
- 为什么需要：RPG 成长感很大一部分来自物品和装备，这一阶段验证运行时实例和属性 modifier 设计。
```text
ItemDefinition
ItemInstance
InventoryModel
InventoryController
EquipmentController
GrantItemEffect
Pickup scene
Inventory UI minimal
```

验证：

```text
Enemy drops sword
Player picks up sword
Inventory contains sword
Equip sword
Attack stat increases
```

---

## Phase 4: Room / Run Slice

### 概念说明

- 是什么：把单房间战斗接成 roguelike run 的阶段。
- 负责什么：实现 RoomController、RunDirector、简单 DungeonGenerator、清房间检测、奖励选择和进入下一房间。
- 为什么需要：只有能从一个房间推进到下一个房间，Mkit 才真正支持 roguelike 玩法循环。
```text
RoomDefinition
RoomRuntime
EntityDefinition
EntitySpawner
RoomController
RunState
RunDirector
DungeonGenerator
RewardDefinition
RewardSystem
RewardSelectionUI
```

验证：

```text
Start run
Enter room
Kill enemies
Choose reward
Enter next room
Die or finish run
```

---

## Phase 5: Save / Meta Progression

### 概念说明

- 是什么：存档和局外成长阶段。
- 负责什么：实现 SaveManager、Saveable、版本迁移、永久升级、解锁内容和设置保存。
- 为什么需要：Roguelite 需要跨 run 的长期目标；没有持久化，装备、解锁和 Meta Progression 都无法可靠保留。
```text
Saveable
SaveManager
SaveMigration
ProgressionState
ProgressionSystem
UpgradeDefinition
Meta currency
Permanent upgrade save/load
```

验证：

```text
Complete run
Gain currency
Buy upgrade
Restart game
Upgrade persists
```

---

---

# 28. Example Usage — 完整 Vertical Slice 示例

下面是一个最小 playable combat slice 的串联示例。

## 28.1 PlayerInputReader

```gdscript
class_name PlayerInputReader
extends Node

@export var player_entity_id: String = "player_001"

func _physics_process(delta: float) -> void:
    var router := ServiceRegistry.get_service("commands") as CommandRouter

    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction != Vector2.ZERO:
        router.dispatch(GameCommand.create(
            BuiltinCommands.MOVE,
            player_entity_id,
            player_entity_id,
            {"direction": direction}
        ))

    if Input.is_action_just_pressed("attack"):
        router.dispatch(GameCommand.create(
            BuiltinCommands.ATTACK,
            player_entity_id,
            player_entity_id,
            {"direction": direction if direction != Vector2.ZERO else Vector2.RIGHT}
        ))

    if Input.is_action_just_pressed("ability_1"):
        router.dispatch(GameCommand.create(
            BuiltinCommands.CAST_ABILITY,
            player_entity_id,
            player_entity_id,
            {
                "ability_id": "ability.fireball_basic",
                "direction": direction if direction != Vector2.ZERO else Vector2.RIGHT
            }
        ))
```

## 28.2 Player MoveState

```gdscript
class_name PlayerMoveState
extends State

func enter(context: Dictionary = {}) -> void:
    _play("run")

func physics_update(delta: float) -> void:
    var direction := blackboard.get_value("move_direction", Vector2.ZERO)
    if direction == Vector2.ZERO:
        request_transition("Player/Alive/Locomotion/Idle", {"reason": "no_move_input"})
        return

    var stats := owner_entity.get_node("Components/StatsComponent") as StatsComponent
    var speed := stats.get_stat_value("move_speed", 160.0)
    owner_entity.velocity = direction * speed
    owner_entity.move_and_slide()

func handle_command(command: GameCommand) -> bool:
    match command.command_type:
        BuiltinCommands.MOVE:
            blackboard.set_value("move_direction", command.get_vector2("direction"))
            return true
        BuiltinCommands.ATTACK:
            return request_transition("Player/Alive/Combat/BasicAttack", {"command": command})
        BuiltinCommands.CAST_ABILITY:
            return request_transition("Player/Alive/Combat/CastAbility", {"command": command})
    return false

func _play(anim_name: String) -> void:
    var anim := owner_entity.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
    if anim != null:
        anim.play(anim_name)
```

## 28.3 Player CastAbilityState

```gdscript
class_name PlayerCastAbilityState
extends State

func enter(context: Dictionary = {}) -> void:
    var command := context.get("command") as GameCommand
    if command == null:
        request_transition("Player/Alive/Locomotion/Idle", {"reason": "missing_command"})
        return

    var ability_id := command.get_string("ability_id")
    var ability_controller := owner_entity.get_node("Controllers/AbilityController") as AbilityController

    var gameplay_context := GameplayContext.from_command(command, owner_entity, _find_target(command))
    gameplay_context.ability_id = ability_id

    var ok := ability_controller.cast(ability_id, gameplay_context)
    if not ok:
        request_transition("Player/Alive/Locomotion/Idle", {"reason": "cast_failed"})
        return

    request_transition("Player/Alive/Locomotion/Idle", {"reason": "cast_started"})

func _find_target(command: GameCommand) -> Node:
    # MVP: 找最近 enemy。后续可换成 targeting system。
    var enemies := get_tree().get_nodes_in_group("enemy")
    var best: Node = null
    var best_distance := INF
    for enemy in enemies:
        var d := owner_entity.global_position.distance_to(enemy.global_position)
        if d < best_distance:
            best = enemy
            best_distance = d
    return best
```

## 28.4 Enemy Death Drop 示例

```gdscript
class_name EnemyDropOnDeath
extends Node

@export var loot_table_id: String = "loot.goblin_common"
@export var player_path: NodePath

func _ready() -> void:
    var health := owner.get_node("Components/HealthComponent") as HealthComponent
    health.died.connect(_on_died)

func _on_died(owner_entity: Node) -> void:
    var player := get_node(player_path)
    var ctx := GameplayContext.new()
    ctx.source = owner_entity
    ctx.target = player

    var loot := LootSystem.new().roll_table(loot_table_id, ctx)
    var inventory := player.get_node("Controllers/InventoryController") as InventoryController
    for item in loot.item_instances:
        inventory.add_item(item)
```

## 28.5 Debug 验证标准

```text
按下攻击键后，DebugOverlay 应该能看到：

Player:
  State: Player/Alive/Combat/BasicAttack
  Last Command: attack
  Active Action: timed_attack

Enemy:
  HP: 80 / 100

Combat Trace:
  Base Damage: 10
  Attack Power: 5
  Crit: false
  Defense: 2
  Final Damage: 13

Recent Events:
  - damage_applied
  - entity_died
```

