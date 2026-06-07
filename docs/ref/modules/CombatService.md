# CombatService

**层：** Module  
**文件：** `addons/mkit/modules/combat/combat_service.gd`  
**继承：** `extends RefCounted`  
**服务 ID：** `"combat"`

## 职责

伤害结算中枢。公开入口接收 `DamageRequest` 并返回 `DamageResult`；内部流程是 `DamageRequest -> DamageIntent -> DamageResolution -> DamageApplication -> DamageResult`。结算会读取攻防双方 `StatsComponent`，处理闪避、暴击、防御和命中状态掷骰。**只算数，不改血**（扣血由 `HealthComponent.apply_damage` 做）。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `resolve(request: DamageRequest) -> DamageResult` | `DamageResult` | 结算一次伤害，写满 `trace` 各阶段中间值 |
| `resolve_damage_intent(request: DamageRequest) -> DamageIntent` | `DamageIntent` | 将公开请求转成内部意图 |
| `resolve_damage_resolution(intent: DamageIntent) -> DamageResolution` | `DamageResolution` | 执行数值、闪避、暴击、防御和命中状态结算 |
| `to_application(resolution: DamageResolution) -> DamageApplication` | `DamageApplication` | 将结算结果装配成可输出 `DamageResult` 的对象 |

## 结算公式（按序）

```
amount = base_amount
amount += attack_power            # trace["after_attack_power"]
amount *= damage_multiplier       # trace["after_damage_multiplier"]
若暴击: amount *= crit_damage     # trace["after_crit"]
amount = max(0, amount - defense) # trace["after_defense"]
```
读取的属性：source 的 `attack_power` / `damage_multiplier` / `crit_chance` / `crit_damage`；target 的 `defense` / `evade_chance`。缺 `StatsComponent` 时取默认值。

## 使用模式

### 最小示例（Level 1）

```gdscript
var combat := ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService
var req := DamageRequest.new()
req.source = attacker
req.target = victim
req.base_amount = 20.0
var result := combat.resolve(req)
print(result.final_amount, result.was_critical)
```

### 典型场景（Level 2）

```gdscript
# 自定义攻击：结算后自己扣血并读 trace 调试
func _deal_custom_damage(attacker: Node, victim: Node) -> void:
    var combat := ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService
    if combat == null:
        return
    var req := DamageRequest.new()
    req.source = attacker
    req.target = victim
    req.base_amount = 30.0
    req.can_crit = true
    req.on_hit_statuses = [{"status_id": "status.poison", "chance": 0.5, "stacks": 1, "duration": -1.0}]
    var result := combat.resolve(req)
    if result.was_evaded:
        print("闪避！")
        return
    var health := EntityContract.get_component(victim, "HealthComponent") as HealthComponent
    if health != null:
        health.apply_damage(result)   # 这一步才真正扣血 + 发事件 + 挂中毒
    # 调试：看每阶段中间值
    print(result.trace)   # {base, after_attack_power, after_damage_multiplier, after_crit, after_defense}
```

## 相关

- → [DamageRequest](DamageRequest.md) · [DamageIntent](DamageIntent.md) · [DamageResolution](DamageResolution.md) · [DamageApplication](DamageApplication.md) · [DamageResult](DamageResult.md) · [ref/modules/HealthComponent.md](HealthComponent.md)
- → [cookbook/03_health_and_stats.md](../../cookbook/03_health_and_stats.md) · [pipeline.md — Damage Resolution](../../pipeline.md#7-damage-resolution)
