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
| 用 `EffectService.execute(effect, ctx)` 触发伤害 | `DamageRequest -> DamageIntent -> DamageResolution -> DamageApplication -> DamageResult`、暴击、防御、闪避、广播 `damage_applied` 事件 |
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
    _effect_svc = ServiceRegistry.get_port(ServiceRegistry.SERVICE_EFFECTS) as EffectService
    _event_svc = ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService

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
    var sm := get_node("StateMachine") as StateMachine
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

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `DealDamageEffect` 执行失败，原因 `no_health_component` | `EntityContract` 找不到目标的 `HealthComponent` | 确认目标在 `EntityRoot` 下，且默认布局中存在 `Components/HealthComponent` |
| 伤害为 0 | `DamageResult.was_evaded = true`、base_amount = 0 或防御抵消 | 检查 `DealDamageEffect.base_amount`、目标 `evade_chance` / `defense` 和 `DamageResult.trace` |
| `entity_died` 未触发 | `HealthComponent.die()` 未被调用 | 确认 HP 确实降到 0；`die()` 内部有 `dead` 标记防止重复触发 |
| `EventService` 为 null | Bootstrap 未运行 | 确认 Bootstrap 场景是第一个场景 |
| 伤害一直相同，无暴击 | `StatsComponent` 中 `crit_chance` = 0 | 在 `base_stats` 里设 `"crit_chance": 0.3` |

## 延伸阅读

- [HealthComponent ref](../ref/modules/HealthComponent.md)
- [StatsComponent ref](../ref/modules/StatsComponent.md)
- [DealDamageEffect ref](../ref/modules/DealDamageEffect.md)
- [GameplayContext ref](../ref/kernel/GameplayContext.md) — source / target / amount / tags
- [EffectService ref](../ref/kernel/EffectService.md) — execute / execute_many / trace
- [pipeline.md — Damage Resolution](../pipeline.md#7-damage-resolution) — 伤害结算完整时序
