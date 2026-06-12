# Recipe 19：XP 曲线与升级树配置  ·  难度 ★★☆  ·  预计 20 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

成长系统从「能用」变成「可调」：XP 曲线按公式或逐级表精确控制；升级时自动加属性；再用 `UpgradeDefinition` 搭一棵**花货币买的升级树**（攻击强化 → 前置解锁 → 内容解锁），`ProgressionService.unlock_or_level_up()` 一行驱动，状态开箱即存。

[Recipe 11](11_progression_and_save.md) 里 XP 和存档混在一起讲；这一篇单独讲 progression 的**配置面**：曲线参数怎么算、升级奖励怎么接、升级树怎么搭。

## 前置

- 需完成：[Recipe 11](11_progression_and_save.md)（`ExperienceComponent` 已在吃 XP，`ProgressionService` 有货币）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 调 `ExperienceCurve` 参数（公式或逐级表）| `add_xp()` 累计、跨级结转、发 `level_up` / `xp_changed` |
| 监听 `level_up`，发奖励（属性/技能点）| — |
| 创建 `UpgradeDefinition` (.tres)：花费 / 前置 / 效果 | `can_unlock()` 校验等级上限、前置、货币；`unlock_or_level_up()` 扣钱、跑 `effects`、记录解锁 |
| UI 调 `get_definition()` / `state.get_upgrade_level()` 渲染 | 升级状态随 `ProgressionService`（`Saveable`）自动存档 |

## 关键认知：两套并行的成长轴

- **XP 等级**（`ExperienceComponent`，挂实体）：被动累积，杀敌得 XP，到阈值自动升。每个实体可以各有一个（玩家、宠物）。
- **升级树**（`ProgressionService` + `UpgradeDefinition`，全局）：主动消费，花货币购买，常用于局内强化或 roguelite 的 meta 升级（`is_meta_upgrade`）。

两者都最终落到「执行 effects / 改属性」，但触发方式和归属不同，别混用。

## 步骤

### 步骤 1：精确控制 XP 曲线

`ExperienceCurve.get_xp_required(level)` 的取值顺序：

1. `level >= max_level` → 返回 `0`（满级，不再吃 XP）
2. `xp_thresholds[level-1]` 存在 → 用表里的值
3. 否则 → 公式 `base_xp * growth_factor^(level-1)`

两种风格：

```text
# A. 公式法（默认）：100, 150, 225, 337, ...
base_xp = 100,  growth_factor = 1.5,  xp_thresholds = []

# B. 逐级表：前期手调、后期跟公式（表只有 5 项，6 级起回落到公式）
xp_thresholds = [50, 80, 120, 200, 300]
```

> 注意阈值是**每级所需**（升完一级后 `current_xp` 扣掉该级所需、结转剩余），不是累计总量。

### 步骤 2：升级时发奖励

`level_up` 信号是你接奖励的钩子——加属性、回满血、给技能点（一种货币）：

```gdscript
# 玩家脚本（Recipe 11 步骤 3 的监听处扩展）
xp.level_up.connect(func(old_level: int, new_level: int):
    var stats := EntityContract.get_component(self, "StatsComponent") as StatsComponent
    if stats != null:
        # source_id 用等级标记，存档恢复后不重复叠加由 StatsComponent baseline 机制保证
        stats.add_modifier(StatModifier.from_definition(_level_hp_bonus, "level_%d" % new_level))
    var health := EntityContract.get_component(self, "HealthComponent") as HealthComponent
    if health != null:
        health.current_hp = health.get_max_hp()   # 升级回满
    Mkit.progression().add_currency("skill_point", 1)
)
```

`_level_hp_bonus` 是一个 `StatModifierDefinition`（`stat_id="max_hp"`, `operation=FLAT_ADD`, `value=10`）。

### 步骤 3：创建升级树的 UpgradeDefinition

三个节点：攻击强化（可升 3 级）→ 暴击解锁（需要前者）；外加一个解锁新技能的。

`res://data/upgrades/attack_up.tres`：

| 字段 | 值 |
|------|----|
| `upgrade_id` | `"upgrade.attack_up"` |
| `display_name` | `"攻击强化"` |
| `max_level` | `3` |
| `currency_id` | `"skill_point"` |
| `cost_by_level` | `[1, 2, 3]`（第 N 级花 `cost_by_level[N-1]`；超出表长用最后一项）|
| `effects` | `[ApplyStatModifierEffect：stat_id="attack_power", FLAT_ADD, value=5, apply_to_source=true, duration=-1]` |

`res://data/upgrades/crit_unlock.tres`：

| 字段 | 值 |
|------|----|
| `upgrade_id` | `"upgrade.crit"` |
| `max_level` | `1` |
| `currency_id` | `"skill_point"`，`cost_by_level=[3]` |
| `prerequisite_upgrade_ids` | `["upgrade.attack_up"]`（attack_up 至少 1 级才可买）|
| `effects` | `[ApplyStatModifierEffect：stat_id="crit_chance", FLAT_ADD, value=0.1]` |

`res://data/upgrades/fireball_unlock.tres`：

| 字段 | 值 |
|------|----|
| `upgrade_id` | `"upgrade.fireball"` |
| `currency_id` | `"skill_point"`，`cost_by_level=[2]` |
| `unlock_content_ids` | `["ability.fireball"]`（购买后记入 `unlocked_content_ids`，并发 `content_unlocked`）|

三个 .tres 都加入 `ResourceDatabase.resources`。

### 步骤 4：购买升级

```gdscript
func try_buy_upgrade(upgrade_id: String, player: Node) -> bool:
    var progression := Mkit.progression()
    if not progression.can_unlock(upgrade_id):
        return false   # 满级 / 前置不足 / 钱不够
    var ctx := GameplayContext.new().with_source(player).with_target(player)
    return progression.unlock_or_level_up(upgrade_id, ctx)
```

`unlock_or_level_up()` 一次完成：扣货币 → 升级等级 +1 → 记录 `unlock_content_ids` 解锁 → 用传入 context 执行 `effects` → 发 `currency_changed` / `upgrade_level_changed` / `content_unlocked`。

> 传 context 很重要：`ApplyStatModifierEffect` 要靠 `source` 找到玩家的 `StatsComponent`。不传则属性类效果落不到人身上。

### 步骤 5：升级树 UI 渲染与门禁

```gdscript
var progression := Mkit.progression()
var definition := progression.get_definition("upgrade.attack_up")
var level := progression.state.get_upgrade_level("upgrade.attack_up")
button.text = "%s  Lv.%d/%d  花费 %d" % [
    definition.display_name, level, definition.max_level,
    definition.get_cost_for_level(level + 1),
]
button.disabled = not progression.can_unlock("upgrade.attack_up")
progression.upgrade_level_changed.connect(func(_id, _lv): _refresh_tree())
```

技能门禁用解锁记录：

```gdscript
if progression.state.unlocked_content_ids.has("ability.fireball"):
    pass   # 允许施放 / 显示技能槽
```

### 步骤 6：存档已自动覆盖

`ProgressionService` 是 `Saveable`（`save_id="progression"`），货币、`upgrade_levels`、`unlocked_content_ids` 全部随 [Recipe 11](11_progression_and_save.md) 的 `save_game()` 写入 `roots.progression`，无需任何额外代码。**注意**：升级 `effects` 改的是玩家 `StatsComponent`，那部分靠实体的 `EntitySaveAgent` 恢复——两边都要在存档树里。

## 运行验证

1. 杀敌升级 → max_hp +10、回满血、`skill_point` +1
2. `xp_thresholds=[50, ...]` 时 2 级只要 50 XP；删掉表 → 回到公式值 100
3. 没买 attack_up 时 crit 按钮禁用（`can_unlock=false`）；买 1 级后可买
4. attack_up 买满 3 级 → 第 4 次 `can_unlock` 返回 false；`attack_power` 总共 +15
5. 买 fireball → `content_unlocked` 信号、`unlocked_content_ids` 含 `"ability.fireball"`
6. 存档重启 → 升级等级、解锁、剩余技能点全在

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `unlock_or_level_up` 返回 false | 钱不够 / 前置为 0 级 / 已满级 | 先 `can_unlock()` 排查是哪一条 |
| 买了升级属性没变 | 没传 context，effect 找不到目标 | `unlock_or_level_up(id, ctx)` 带上玩家 context |
| 升级效果存档后丢了 | `StatsComponent` 修改没随实体存档 | 玩家要挂 `EntitySaveAgent`（[Recipe 11 步骤 4](11_progression_and_save.md#步骤)）|
| 第 N 级费用不对 | `cost_by_level` 是**下一级**索引 `N-1`；超表长取最后一项 | 按 `get_cost_for_level(next_level)` 的语义填表 |
| 升级到一半不涨了 | `ExperienceCurve.max_level` 到顶 | 调大 `max_level` |
| XP 表只对前几级生效 | `xp_thresholds` 比 `max_level` 短，后面走公式 | 想全表控制就填满 `max_level - 1` 项 |

## 延伸阅读

- [ExperienceCurve ref](../generated/html/classes/ExperienceCurve.html) · [ExperienceComponent ref](../generated/html/classes/ExperienceComponent.html)
- [UpgradeDefinition ref](../generated/html/classes/UpgradeDefinition.html) · [ProgressionService ref](../generated/html/classes/ProgressionService.html)
- [pipeline.md — Progression / Level Up](../pipeline.md#17-progression--level-up)
- [Recipe 11](11_progression_and_save.md) — XP 接线与存档 · [Recipe 23](23_upgrade_choice_rewards.md) — 升级三选一 reward · [Recipe 14](14_shop.md) — 货币的另一个出口
