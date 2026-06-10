# HealthComponent

**层：** Module  
**文件：** `addons/mkit/modules/combat/health/health_component.gd`  
**继承：** `extends SaveableComponent`

## 职责

生命值组件，挂在 `Components/HealthComponent`。消费 `DamageResult` 扣血、发 `damaged`/`died` 信号并经 `EventService` 广播 `CombatEvents.damage_applied` / `CombatEvents.entity_died` 领域事件，并把命中附带状态转交 `StatusEffectController`。最大血量取自同实体 `StatsComponent` 的 `max_hp`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `current_hp` | `float`（@export）| `100.0` | 当前生命 |
| `destroy_on_death` | `bool`（@export）| `false` | 死亡时是否 `queue_free` 实体 |
| `dead` | `bool` | `false` | 是否已死 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_max_hp() -> float` | `float` | 取 `StatsComponent.max_hp`（无则 100）|
| `apply_damage(result: DamageResult) -> void` | — | 扣血、发信号/事件、挂命中状态、可能触发死亡 |
| `heal(amount, source := null) -> void` | — | 治疗（不超过上限）|
| `die(killer := null) -> void` | — | 标记死亡、发 `died` + `entity_died` |
| `revive(percent := 1.0) -> void` | — | 复活到比例血量 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `health_changed` | `current, max_value` | 血量变化 |
| `damaged` | `result: DamageResult` | 受击 |
| `healed` | `amount, source` | 治疗 |
| `died` | `owner_entity` | 死亡 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var hp := EntityContract.get_component(enemy, "HealthComponent") as HealthComponent
hp.died.connect(func(_e: Node): print("敌人死亡"))
```

### 典型场景（Level 2）

```gdscript
# 监听血量做血条 + 死亡处理
func _ready() -> void:
    var hp := EntityContract.get_component(owner, "HealthComponent") as HealthComponent
    if hp == null:
        return
    hp.health_changed.connect(_on_health_changed)
    hp.died.connect(_on_died)


func _on_health_changed(current: float, max_value: float) -> void:
    $HealthBar.value = current / max_value * 100.0


func _on_died(_entity: Node) -> void:
    # destroy_on_death=false 时这里自己处理（播死亡动画后再 free）
    var anim := EntityContract.get_contract_node(owner, "Presentation", "AnimationPlayer") as AnimationPlayer
    if anim != null and anim.has_animation("death"):
        anim.play("death")
        await anim.animation_finished
    owner.queue_free()
```

> 存档：`HealthComponent` 是 `SaveableComponent`，`to_save_data` 存 `current_hp`/`dead`，需由实体下的 `EntitySaveAgent` 收集。

## 相关

- → [DamageResult](DamageResult.md) · [ref/modules/StatsComponent.md](StatsComponent.md) · [ref/modules/HealEffect.md](HealEffect.md)
- → [cookbook/03_health_and_stats.md](../../cookbook/03_health_and_stats.md)
