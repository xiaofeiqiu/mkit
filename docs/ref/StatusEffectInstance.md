# StatusEffectInstance

## 概念说明

StatusEffectInstance 是已经挂在某个实体身上的状态运行时实例。它记录来源、目标、剩余时间、当前层数、tick 计时器和运行时元数据。两个敌人都被燃烧时，它们共享 status.burn 定义，但剩余时间和层数必须各自独立。

## 设计目的

区分静态状态配置（StatusEffectDefinition）和运行时状态（StatusEffectInstance），使同一个状态定义可以同时施加在多个目标上，每个目标的剩余时间、层数和已应用的 modifier ID 相互独立，方便精确过期、移除和调试。

## 文件

`res://addons/mkit/modules/status_effects/status_effect_instance.gd`

## 接口

```gdscript
class_name StatusEffectInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var source: Node = null
var target: Node = null
var remaining_duration: float = 0.0
var tick_timer: float = 0.0
var stacks: int = 1
var applied_modifier_ids: Array[String] = []

func setup(definition: StatusEffectDefinition, source_entity: Node, target_entity: Node, initial_stacks: int, duration_override: float = -1.0) -> void: ...
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
