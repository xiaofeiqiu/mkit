# Recipe 03：血量 / 属性 / 伤害 / 死亡  ·  难度 ★★☆  ·  预计 25 分钟

## 本篇结束后，你的项目新增了什么

玩家有血量（`HealthComponent`）和属性（`StatsComponent`），可以受到伤害。血量归零时触发死亡。控制台打印伤害数值和 `entity_died` 事件。

## 前置

- 需完成：[Recipe 02](02_player_entity.md)（玩家实体场景树已建好）
- 用到的概念：[concepts.md — 模型 1：标准管线](../concepts.md#模型-1标准管线时序图)（Effect → CombatService 段）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 在 `Components/` 下添加 `StatsComponent` 节点，配置 `base_stats` | 属性修改器合并计算（flat / percent / override）|
| 在 `Components/` 下添加 `HealthComponent` 节点，设 `current_hp` | 从 `StatsComponent.get_stat_value("max_hp")` 读上限；死亡后 `die()` |
| 创建 `DealDamageEffect` 资源，配置 `base_amount` | 通过 `EntityContract` 查找 `HealthComponent`，调用 `CombatService.resolve()` 计算最终伤害 |
| 用 `EffectService.execute(effect, ctx)` 触发伤害 | `DamageRequest -> DamageResult`、暴击、防御、闪避、广播 `damage_applied` 事件 |
| 订阅 `EventService.entity_died` 信号，处理死亡逻辑 | 广播 `entity_died` 事件 |

## 步骤

### 步骤 1：在玩家场景树中添加组件

在 `PlayerEntity/Components/` 下添加两个节点：

**StatsComponent（附加内置脚本 `StatsComponent`）**

在 Inspector 中修改 `base_stats`（Dictionary）：
```
max_hp         = 100.0
attack_power   = 15.0
defense        = 2.0
move_speed     = 160.0
```

**HealthComponent（附加内置脚本 `HealthComponent`）**

- `current_hp` = `100.0`
- `destroy_on_death` = `false`（死亡后保留节点，由游戏逻辑处理）

确认场景树：
```
PlayerEntity  (EntityRoot)
├── EntityIdentity
├── StateMachine
│   └── Root
│       ├── Idle
│       └── Move
├── CommandReceiver
├── Components/
│   ├── StatsComponent    ← 新增
│   └── HealthComponent   ← 新增
├── Controllers/
└── Presentation/
```

### 步骤 2：创建 DealDamageEffect 资源

在编辑器 → New Resource → `DealDamageEffect`，保存为 `res://data/effects/test_damage_10.tres`：

- `effect_id` = `"test_damage_10"`
- `base_amount` = `10.0`
- `damage_type` = `"physical"`
- `can_crit` = `true`

### 步骤 3：用代码触发伤害（测试用）

在主场景或玩家控制器中添加一个测试触发，按 Space 对玩家造成伤害：

```gdscript
# res://game/debug/damage_tester.gd
extends Node

var _effect_svc: EffectService = null
var _event_svc: EventService = null
var _player: Node = null

@export var damage_effect: DealDamageEffect = null  # 拖入 test_damage_10.tres


func _ready() -> void:
    _effect_svc = Mkit.effects()
    _event_svc = Mkit.events()

    # 订阅死亡事件
    if _event_svc != null:
        _event_svc.entity_died.connect(_on_entity_died)

    # 订阅伤害事件（可选，用于调试）
    if _event_svc != null:
        _event_svc.damage_applied.connect(_on_damage_applied)

    # 拿到玩家节点（按实际场景结构调整）
    _player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept") and _player != null:
        _deal_test_damage()


func _deal_test_damage() -> void:
    if _effect_svc == null or damage_effect == null or _player == null:
        return
    var ctx := GameplayContext.new()
    ctx.source = _player          # 攻击来源（测试用自伤）
    ctx.target = _player          # 受击目标
    var result := _effect_svc.execute(damage_effect, ctx)
    if not result.success:
        print("Damage failed: %s" % result.failure_reason)


func _on_damage_applied(result: DamageResult) -> void:
    print("Damage applied: final=%.1f crit=%s" % [result.final_amount, result.was_critical])


func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
    print("Entity died: %s" % entity_id)
```

将 `DamageTester` 挂到主场景并将 `damage_effect` 属性拖入资源文件。

### 步骤 4：让玩家加入 "player" group

在玩家实体场景根节点 Inspector → Groups → 添加 `"player"`，供 `get_first_node_in_group("player")` 定位。

### 步骤 5：（可选）让死亡状态可见

在 `PlayerIdleState` 或监听 `HealthComponent.died` 信号：

```gdscript
# 在玩家实体场景的 _ready 中
func _ready() -> void:
    var health := EntityContract.get_component(self, "HealthComponent") as HealthComponent
    if health != null:
        health.died.connect(_on_player_died)


func _on_player_died(_entity: Node) -> void:
    # 切到死亡状态、播放动画、显示 Game Over 等
    var sm := EntityContract.get_state_machine(self)
    if sm != null:
        sm.transition_to("Root/Dead")  # Recipe 04+ 再加 Dead 状态
```

## 运行验证

按 Space 键触发伤害：

```
Damage applied: final=9.3 crit=false
Damage applied: final=9.3 crit=false
...
Damage applied: final=8.1 crit=true     ← 暴击时 final 更高
Entity died: player_12345               ← 10次后 HP 归零
```

在 Remote 调试器可查看 `HealthComponent.current_hp` 的实时变化。

## 字段参考

### StatsComponent

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `base_stats` | Dictionary（默认含 max_hp / attack_power / defense / move_speed / max_mana / max_stamina / attack_speed / crit_chance / crit_damage / cooldown_reduction / luck / damage_multiplier / healing_multiplier）| 实体基础属性表，key 为 stat id。`max_<资源id>` 还兼任 `ResourcePoolComponent` 对应池的上限（如 `max_mana`，[Recipe 05](05_ability.md) 步骤 3 依赖它）| 见步骤 1；可自由加自定义 stat id |

### HealthComponent

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `current_hp` | float = 100.0 | 当前生命值；`_ready` 时被夹到 `max_hp`（来自 StatsComponent，无则 100）以内 | 见步骤 1 |
| `destroy_on_death` | bool = false | 死亡时是否自动 `queue_free()` 拥有者实体。敌人通常 `true`（掉落/事件已在释放前广播）；玩家保持 `false`，由游戏逻辑接管死亡演出（步骤 5）| 敌人实体设 `true`（[Recipe 06](06_ai_enemy.md)）|

### StatDefinition（可选——用 .tres 描述属性的元信息）

`base_stats` 直接用字符串 key 即可工作；当你需要给属性面板、编辑器校验或游戏侧规则提供元信息时，才建一个 `StatDefinition` 入库。当前 `StatsComponent` 的数值计算**不自动读取** `StatDefinition.default_value/min_value/max_value`：运行时基础值来自 `base_stats`，夹取要靠 `StatModifierDefinition.CLAMP_MIN/CLAMP_MAX` 或你的游戏代码执行。

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `stat_id` | String = "" | 稳定 id，对应 `base_stats` 的 key | 必填 |
| `display_name` | String = "" | UI 显示名 | 做属性面板时填 |
| `default_value` | float = 0.0 | 属性的设计默认值/显示默认值。**当前 `StatsComponent.get_stat_value()` 不会自动回退到这里**；需要时由 UI、内容校验或你的游戏代码读取 | 给属性面板、模板生成器或自定义校验用 |
| `min_value` / `max_value` | float = -INF / INF | 属性允许范围的元信息；±INF = 不限制。**当前运行时不会自动按它 clamp** | UI 输入限制、内容校验；运行时夹取请用 `CLAMP_MIN/CLAMP_MAX` modifier |
| `is_percent` | bool = false | 是否按百分比**显示**（0.05 → "5%"）；只影响 UI 约定，不改变数值计算 | `crit_chance`、`cooldown_reduction` 等设 `true` |

### StatModifierDefinition（buff / 装备改属性的最小单元）

挂在 `StatusEffectDefinition.stat_modifiers`（[Recipe 12](12_status_effects.md)）或装备上，由 `StatsComponent.add_modifier` 参与计算：

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `modifier_id` | String = "" | 修饰器 id；`remove_modifier` 按它移除，`UNIQUE` 等叠加规则按它判重 | 必填 |
| `stat_id` | String = "" | 修改哪个属性（`base_stats` 的 key）| 必填 |
| `operation` | enum = FLAT_ADD | 运算类型，6 个取值（计算顺序固定，见下）：<br>`FLAT_ADD` — 加法：所有 FLAT_ADD 先求和加到基础值<br>`PERCENT_ADD` — 加法百分比：所有 PERCENT_ADD 求和后 `×(1 + 总和)`（0.1 = +10%，两个 0.1 = +20%）<br>`PERCENT_MULTIPLY` — 乘法百分比：逐个连乘（两个 1.1 = ×1.21）<br>`OVERRIDE` — 无视前面全部计算直接覆盖为 value（多个 OVERRIDE 时 priority 最大的生效）<br>`CLAMP_MIN` / `CLAMP_MAX` — 最后把结果夹到下限/上限（多个时取最严格的）<br>完整公式：`(base + ΣFLAT) × (1 + ΣPERCENT_ADD) × ΠPERCENT_MULTIPLY → OVERRIDE → CLAMP` | buff 加攻用 FLAT_ADD；"伤害提高 20%" 用 PERCENT_ADD；"虚弱：攻击减半" 用 PERCENT_MULTIPLY(0.5) |
| `value` | float = 0.0 | 数值；含义随 operation 变化（FLAT_ADD 是加量，PERCENT_MULTIPLY 是倍率）| 必填 |
| `priority` | int = 0 | 排序优先级，数值小的先参与。对 FLAT_ADD / PERCENT_ADD（求和）和 CLAMP（取最严）**没有影响**；只影响多个 `OVERRIDE` 之间谁最终生效（排序靠后者赢）| 多 OVERRIDE 冲突时才需要 |
| `stacking_rule` | enum = STACK | 重复 `add_modifier` 时的去重规则，5 个取值：<br>`STACK` — 无脑共存，全部参与计算<br>`REPLACE_SAME_SOURCE` — 同 `source_id` + 同 `modifier_id` 的旧条目被替换（同一来源刷新自己的 buff）<br>`HIGHEST_ONLY` — 同 `modifier_id` 只留 value 最大的（新值更小则拒绝加入）<br>`LOWEST_ONLY` — 同上但留最小<br>`UNIQUE` — 同 `modifier_id` 只留最新一条，无视来源 | 可叠的毒用 STACK；不同来源的同名光环不叠加用 UNIQUE |
| `tags` | Array[String] = [] | 标签；供查询/事件过滤，mkit 不做规则判定 | 一般留空 |

> `StatModifierDefinition` 是静态定义；运行时实际挂到组件上的是 `StatModifier`（带 `source_id`、`remaining_duration`）。状态效果到期时按 `source_id`（= 状态实例 id）整组移除。

### ResourcePoolComponent

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `starting_values` | Dictionary = {} | 资源池**当前值**初值表，如 `{"mana": 50.0}`。上限不在这里配——来自 StatsComponent 的 `max_<资源id>` stat；不写的资源默认满值开局。它是技能 `cost_type` 的扣费来源（[Recipe 05](05_ability.md) 步骤 3 完整演示）| 半蓝/空怒气开局时填 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `DealDamageEffect` 执行失败，原因 `no_health_component` | `EntityContract` 找不到目标的 `HealthComponent` | 确认目标在 `EntityRoot` 下，且默认布局中存在 `Components/HealthComponent` |
| 伤害为 0 | `DamageResult.was_evaded = true`、base_amount = 0 或防御抵消 | 检查 `DealDamageEffect.base_amount`、目标 `evade_chance` / `defense` 和 `DamageResult.trace` |
| `entity_died` 未触发 | `HealthComponent.die()` 未被调用 | 确认 HP 确实降到 0；`die()` 内部有 `dead` 标记防止重复触发 |
| `EventService` 为 null | Bootstrap 未运行 | 确认 Bootstrap 场景是第一个场景 |
| 伤害一直相同，无暴击 | `StatsComponent` 中 `crit_chance` = 0 | 在 `base_stats` 里设 `"crit_chance": 0.3` |

## 延伸阅读

- [HealthComponent ref](../generated/html/classes/HealthComponent.html)
- [StatsComponent ref](../generated/html/classes/StatsComponent.html)
- [DealDamageEffect ref](../generated/html/classes/DealDamageEffect.html)
- [GameplayContext ref](../generated/html/classes/GameplayContext.html) — source / target / tags / payload
- [EffectService ref](../generated/html/classes/EffectService.html) — execute / execute_many / trace
- [pipeline.md — Damage Resolution](../pipeline.md#7-damage-resolution) — 伤害结算完整时序
