# StatusEffectInstance

## 概念说明

StatusEffectInstance 是已经挂在某个实体身上的状态运行时实例。它记录来源、目标、剩余时间、当前层数、tick 计时器和运行时元数据。两个敌人都被燃烧时，它们共享 status.burn 定义，但剩余时间和层数必须各自独立。

## 设计目的

区分静态状态配置（StatusEffectDefinition）和运行时状态（StatusEffectInstance），使同一个状态定义可以同时施加在多个目标上，每个目标的剩余时间、层数和已应用的 modifier ID 相互独立，方便精确过期、移除和调试。

## 文件

`res://addons/mkit/modules/status_effects/status_effect_instance.gd`

## 字段说明

- **instance_id**：运行时物品/对象实例 ID。例：两把 Iron Sword 都来自 item.sword_iron，但一把有暴击词缀、一把有耐久损耗，所以必须有不同 instance_id。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **source_id**：来源稳定 ID。存档时用它记录状态来源，避免把 source 节点路径直接写入 payload。
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **remaining_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tick_timer**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **stacks**：代码字段。层数。
- **applied_modifier_ids**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name StatusEffectInstance
extends RefCounted
var instance_id: String = ""
var definition_id: String = ""
var source_id: String = ""
var source: Node = null
var target: Node = null
var remaining_duration: float = 0.0
var tick_timer: float = 0.0
var stacks: int = 1
var applied_modifier_ids: Array[String] = []
func setup( definition: StatusEffectDefinition, source_entity: Node, target_entity: Node, initial_stacks: int, duration_override: float = -1.0 ) -> void
```

## 函数使用场景

- **`setup(definition, source_entity, target_entity, initial_stacks, duration_override)`**：初始化实例，生成唯一 instance_id（用于 StatsComponent modifier 的 source_id），绑定 definition_id、source、target，设置初始 stacks 和持续时间（`duration_override > 0` 则覆盖 definition.duration）。StatusEffectController.apply_status() 在创建新实例时调用。

## 使用示例

```gdscript
var instance := StatusEffectInstance.new()
instance.setup(burn_definition, player, enemy, 1)

print("Instance ID: ", instance.instance_id)
print("Remaining: ", instance.remaining_duration)
print("Stacks: ", instance.stacks)
```
