# CombatResolver

## 概念说明

CombatResolver 是伤害结算规则引擎。它读取攻击者的攻击力、暴击率、伤害倍率，以及防御者的防御值、元素抗性等，产出完整的 DamageResult。伤害公式经常需要调整，集中在一个 resolver 中才容易测试和调平衡。

## 设计目的

把伤害计算公式集中到一处，使平衡性调整（改防御公式、改暴击计算）只需修改此文件，且支持通过固定 Random seed 复现同一结果，方便测试和 bug 追踪。

## 文件

`res://addons/mkit/modules/combat/combat_resolver.gd`

## 接口

```gdscript
class_name CombatResolver
extends RefCounted
func resolve(request: DamageRequest) -> DamageResult
```

CombatResolver 是无生命周期的 RefCounted 服务，由 `GameBootstrap` 以服务 id `combat` 注册（与 `random`、`time`、`effects` 同属注册但不挂入节点树的服务）。调用方通过 `ServiceRegistry.get_service("combat")` 获取，统一走服务注册表，便于测试时 mock 或替换；在没有注册表的轻量上下文里可回退到 `CombatResolver.new()`。

## 函数使用场景

- **`resolve(request)`**：核心公开接口。按顺序：读取攻防属性、叠加 attack_power 和 damage_multiplier、掷暴击、扣防御，产出 final_amount，再调用 `_roll_on_hit_statuses` 掷状态附加概率。结算 trace 记录每个阶段的中间值，供 DebugOverlay 展示。
- **`_roll_on_hit_statuses(request, result)`**：对 `request.on_hit_statuses` 中每项用 RandomService 掷概率；命中的状态写入 `result.applied_status_effects` 和 `result.status_applications`。闪避或格挡时跳过。

## 使用示例

```gdscript
func deal_direct_damage(source: Node, target: Node, amount: float) -> void:
    var request := DamageRequest.new()
    request.source = source
    request.target = target
    request.base_amount = amount

    var resolver := ServiceRegistry.get_service("combat") as CombatResolver
    var result := resolver.resolve(request)
    var health := target.get_node("Components/HealthComponent") as HealthComponent
    health.apply_damage(result)
```

### 查看 trace

```gdscript
var result := CombatResolver.get_default().resolve(request)
print("Base: ", result.trace.get("base"))
print("After attack power: ", result.trace.get("after_attack_power"))
print("After crit: ", result.trace.get("after_crit"))
print("Final: ", result.final_amount)
```
