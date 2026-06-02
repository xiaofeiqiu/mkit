# AbilityInstance

## 概念说明

AbilityInstance 是某个实体身上正在使用的技能运行时实例。它记录技能拥有者、剩余冷却、当前 charges、技能等级、临时修改和是否启用。玩家和敌人都可能拥有 ability.fireball_basic，但它们的冷却、等级和 charges 是各自独立的。

## 设计目的

区分静态技能配置（AbilityDefinition）和运行时状态（AbilityInstance），使同一技能定义可被多个实体复用，每个实体的冷却进度、charges 和等级相互独立，也便于存档/读档只需保存 definition_id 和少量运行时字段。

## 文件

`res://addons/mkit/modules/abilities/ability_instance.gd`

## 字段说明

- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **owner**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **cooldown_remaining**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **current_charges**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **runtime_level**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **enabled**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **temporary_modifiers**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

## 接口

```gdscript
class_name AbilityInstance
extends RefCounted
var definition_id: String = ""
var owner: Node = null
var cooldown_remaining: float = 0.0
var current_charges: int = 1
var runtime_level: int = 1
var enabled: bool = true
var temporary_modifiers: Dictionary = {}
func setup(definition: AbilityDefinition, owner_entity: Node) -> void
func tick(delta: float) -> void
func is_cooldown_ready() -> bool
func start_cooldown(definition: AbilityDefinition, cooldown_reduction: float = 0.0) -> void
func restore_charge(definition: AbilityDefinition) -> void
```

## 函数使用场景

- **`setup(definition, owner_entity)`**：初始化实例，绑定 definition_id、owner 和初始 charges。AbilityController.register_ability() 在注册技能时调用。
- **`tick(delta)`**：减少 `cooldown_remaining`，由 AbilityController._process() 每帧调用。冷却完毕后 `is_cooldown_ready()` 返回 true。
- **`is_cooldown_ready()`**：AbilityController 和 CooldownReadyCondition 调用此方法判断是否可以释放技能（冷却为零且还有 charges）。
- **`start_cooldown(definition, cooldown_reduction)`**：技能成功释放后调用，将 cooldown_remaining 设为 `definition.cooldown * (1 - cdr)`，并消耗一个 charge。
- **`restore_charge(definition)`**：特殊道具或奖励可恢复 charge，恢复量不超过 definition.charges 上限。

## 使用示例

```gdscript
var instance := AbilityInstance.new()
instance.setup(fireball_definition, player)

# 每帧推进冷却
instance.tick(delta)

# 判断并释放
if instance.is_cooldown_ready():
    instance.start_cooldown(fireball_definition, 0.10) # 10% CDR
```
