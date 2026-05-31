# Foundation and Folder Structure

---

> 目标：请基于本规格实现一个 Godot 4.x 可复用 2D RPG / Roguelike Mkit。  
> 语言：GDScript 2.0。  
> 风格：强类型、模块化、可测试、数据驱动、低耦合。  
> 实现方式：先实现 Runtime Kernel，再按 vertical slice 实现 Combat、Ability、Inventory、Room/Run、Save。

---

---

## 0. 总体实现约束

### 概念说明

- 是什么：Mkit 的总设计边界和实现纪律，规定哪些代码属于可复用框架、哪些代码属于具体游戏内容。
- 负责什么：约束依赖方向、数据/运行时/节点分层、命令/状态/Action/Effect 的调用链，以及 GDScript 强类型和低耦合写法。
- 为什么需要：如果没有这组约束，AI 很容易把 Fireball、Goblin、具体房间奖励等写死进框架里，最后这个 Mkit 就不能服务多个 RPG/roguelike 项目。
### 0.1 核心架构边界

Mkit 只提供可复用机制，不写具体游戏内容。

Mkit 可以知道：

```text
GameCommand
GameplayContext
State
GameAction
GameEffect
Condition
DamageRequest
DamageResult
AbilityDefinition
ItemDefinition
RoomDefinition
RunState
RewardOption
```

Mkit 不可以硬编码：

```text
Fireball of Red Mage
Goblin King
Iron Sword Chapter 2
Forest Room 03
Specific ad revive economy
Specific shop price
Specific story quest
```

### 0.2 统一调用主链路

所有主要玩法尽量走这个链路：

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

### 0.3 Resource / Instance / Node 分层

```text
Resource = 静态定义，可复用，可序列化
Runtime Instance = 运行时状态，可变
Node = 场景树行为、生命周期、信号、物理交互
```

示例：

```text
AbilityDefinition -> AbilityInstance -> AbilityController
ItemDefinition -> ItemInstance -> InventoryController / EquipmentController
StatusEffectDefinition -> StatusEffectInstance -> StatusEffectController
RoomDefinition -> RoomRuntime -> RoomController
EntityDefinition -> EntityRoot / EntitySpawner
UpgradeDefinition -> ProgressionState -> ProgressionSystem
```

### 0.4 GDScript 约定

所有核心文件使用：

```gdscript
class_name Xxx
extends XxxBase
```

推荐使用类型标注：

```gdscript
var entity_id: String = ""
var amount: float = 0.0
var tags: Array[String] = []
func can_cast(context: GameplayContext) -> bool:
    return true
```

尽量避免：

```gdscript
# 避免核心代码长期依赖裸 Dictionary
func do_something(data: Dictionary) -> void:
    pass
```

可以在 MVP 阶段允许 payload Dictionary，但外层必须有明确对象包装。

---

