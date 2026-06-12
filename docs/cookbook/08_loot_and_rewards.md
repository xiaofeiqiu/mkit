# Recipe 08：房间清空触发战利品与奖励选择  ·  难度 ★★★  ·  预计 30 分钟

## 本篇结束后，你的项目新增了什么

房间清空后不再直接进下一间，而是弹出**三选一奖励界面**。`RoomController` 用 `LootService` 从 `reward_pool_ids` 抽出若干 `RewardOption`，`RunDirector` 发 `choosing_reward` 信号；你的 UI 显示选项，玩家点选后 `RunDirector.select_reward()` 执行该奖励的 effect 链（回血 / 给物品 / 加货币），然后才进下一个房间。

## 前置

- 需完成：[Recipe 07](07_room.md)（房间序列已能推进）
- 用到的概念：[concepts.md — 模型 1：标准管线](../concepts.md#模型-1标准管线时序图)（reward 的 effect 链）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `RewardDefinition` (.tres)，配 `weight` / `effects` | `LootService.generate_options()` 按权重无放回抽取，构造 `RewardOption` |
| 给 `RoomDefinition.reward_pool_ids` 填上 reward id | `RoomController.generate_reward()` 在清空时生成选项 |
| 监听 `RunDirector.choosing_reward`，显示选项 UI | `RunDirector` 暂停推进，进入 `choosing_reward` 状态 |
| 玩家点选 → 调 `run_director.select_reward(option)` | `RewardCoordinator` → `LootService.apply_selected()` 跑 effect、发 `reward_selected`，再进下一间 |

## 步骤

### 步骤 1：创建 RewardDefinition

新建 Resource → `RewardDefinition`，存为 `res://data/rewards/reward_heal.tres`：

| 字段 | 值 |
|------|----|
| `reward_id` | `"reward.heal"` |
| `display_name` | `"治疗药剂"` |
| `description` | `"立即恢复 40 点生命"` |
| `rarity` | `"common"` |
| `weight` | `2.0`（权重越大越常出现）|
| `effects` | `[res://data/effects/reward_heal_effect.tres]` |

`reward_heal_effect.tres` 是一个 `HealEffect`：
- `effect_id` = `"reward_heal"`
- `base_amount` = `40.0`

> `HealEffect` 在 `context.target == null` 时回退到 `context.source`。`RewardCoordinator` 会把 `source` 和 `target` 都设成玩家，所以药剂作用在玩家身上，无需额外配置。

再做两个让玩家有得选（reward 默认抽 3 个，池至少要有 3 个不同 id）：

- `reward.attack_up`（`ApplyStatModifierEffect`：`stat_id="attack_power"`, `operation=FLAT_ADD`, `value=5`, `apply_to_source=true`, `duration=-1` 永久）
- `reward.gold`（`AddCurrencyEffect`：`currency_id="gold"`, `amount=25`）

> `AddCurrencyEffect` / `SpendCurrencyEffect` 的 `currency_id` / `amount` 是普通 `var`（非 `@export`），无法在 Inspector 直接填。要在编辑器里配奖励，优先用带 `@export` 的 effect（`HealEffect`、`ApplyStatModifierEffect`、`GrantItemEffect`）；货币奖励可改为在代码里构造，或在 [Recipe 11](11_progression_and_save.md) 用 `ProgressionService` 直接加。

把三个 `RewardDefinition`（`reward.heal` / `reward.attack_up` / `reward.gold`）都加入 `ResourceDatabase.resources`。`HealEffect` 等 effect 资源继承 `GameEffect extends Resource`，**不**继承 `ContentDefinition`，不需要入库。

### 步骤 2：把 reward 池挂到房间

打开 `res://data/rooms/combat_room_a.tres`，把 `reward_pool_ids` 填上：

```
reward_pool_ids = ["reward.heal", "reward.attack_up", "reward.gold"]
```

`RoomController.reward_count`（默认 3）决定抽几个。池里有 3 个、抽 3 个 → 三个都出现（无放回）。

### 步骤 3：搭建奖励选择 UI 场景

新建场景 `res://game/ui/reward_selection.tscn`，根节点用内置类 `RewardSelectionUI`（`extends Control`），并加一个名为 `OptionContainer` 的子节点（`VBoxContainer`）：

```
RewardSelection  (RewardSelectionUI)
└── OptionContainer  (VBoxContainer)   # 名字必须是 "OptionContainer"
```

`RewardSelectionUI.setup(data)` 会读 `data.options` 与 `data.run_director`，为每个选项生成一个按钮；点击后调用 `run_director.select_reward(option)` 并关闭自己。**你不需要给它写脚本**，内置类已实现。

### 步骤 4：用 UIManager 注册并打开该界面

在主场景加一个 `UIManager` 节点（若还没有），配置 `screen_scene_map`：

```
screen_scene_map = {
    "reward_selection": "res://game/ui/reward_selection.tscn"
}
```

并确保 `UIManager` 下有 `ScreenRoot` 子节点（`screen_root_path` 默认 `"ScreenRoot"`）作为界面挂载点。`UIManager._ready()` 会把自己注册为 `"ui"` 服务，供 `RewardSelectionUI` 关闭时调用。

### 步骤 5：监听 choosing_reward，弹出界面

在主场景脚本里连上 `choosing_reward`：

```gdscript
# res://game/main.gd（在 _ready 中追加）
func _ready() -> void:
    # ...（Recipe 07 的连接保持不变）

    _director.choosing_reward.connect(_on_choosing_reward)
    _director.start_run(12345)


func _on_choosing_reward(options: Array[RewardOption]) -> void:
    var ui := Mkit.ui()
    if ui == null:
        # 没有 UI 时退化为自动选第一个，保证 run 能继续（仅供调试）
        if not options.is_empty():
            _director.select_reward(options[0])
        return
    # modal=true 会让 TimeService 暂停游戏，直到玩家选择
    ui.open_screen("reward_selection", {"options": options, "run_director": _director}, true)
```

`UIManager.open_screen()` 实例化 `reward_selection.tscn` → 调 `RewardSelectionUI.setup(data)` → 玩家点按钮 → `run_director.select_reward(option)` → `RewardCoordinator.apply_reward()` 跑 effect → `RunDirector` 自增房间序号、进下一间。

### 步骤 6：（可选）物品奖励需要背包

若想用 `GrantItemEffect` 发物品作为奖励：

1. 在玩家 `Controllers/` 下加 `InventoryController` 节点
2. 创建一个 `ItemDefinition` (.tres)（`item_id="item.potion"`, `stackable=true`, `max_stack=99`），入库
3. `RewardDefinition.effects` 用 `GrantItemEffect`：`item_id="item.potion"`, `quantity=1`, `give_to_source=true`

`GrantItemEffect` 找不到 `Controllers/InventoryController` 会返回失败，奖励链中断且不推进房间——所以背包必须先就位。

### 步骤 7：（可选）敌人死亡掉落（LootTable）

`RewardDefinition` 是"三选一"奖励；loot 模块的另一半是 **`LootTableDefinition` + `LootEntry`** ——按权重 roll 的掉落表（敌人掉材料、宝箱出装备）。两者都由 `LootService` 驱动，但入口不同：奖励走 `generate_options()`（无放回抽 N 个供玩家选择），掉落表走 `roll_table()`（独立 roll N 次，直接给出 `ItemInstance` 结果）。

本节是把死亡掉落接到当前主线的快速版；完整做法、调试和常见错误见 [Recipe 22](22_enemy_death_loot.md)。

新建 Resource → `LootTableDefinition`，存为 `res://data/loot/field_beast_drops.tres` 并入库：

| 字段 | 值 |
|------|----|
| `loot_table_id` | `"loot.field_beast"` |
| `rolls` | `2`（独立 roll 两次）|
| `allow_empty` | `true` |
| `empty_weight` | `1.0`（"什么都不掉"占 1.0 权重参与抽签）|
| `entries` | 两个 `LootEntry`（Inspector 内嵌创建，见下）|

两个 `LootEntry`：

- 兽皮：`content_id="item.beast_hide"`, `weight=3.0`, `min_quantity=1`, `max_quantity=2`
- 兽牙：`content_id="item.beast_fang"`, `weight=1.0`（每次 roll 选中概率 = 1.0 / (1.0+3.0+1.0) = 20%）

`content_id` 指向 `ItemDefinition`（按步骤 6 的方式创建并入库）。接下来新建 Resource → `DeathLootRuleDefinition`，存为 `res://data/loot/field_beast_death_loot.tres` 并入库：

| 字段 | 值 |
|------|----|
| `rule_id` | `"death_loot.field_beast"` |
| `entity_definition_ids` | `["entity.field_beast"]`（若敌人由 `EntitySpawner` 生成，推荐按 definition id 匹配）|
| `required_tags` | `[]`（手摆敌人也可改用 `["field_beast"]` 按 tag 匹配）|
| `loot_table_ids` | `["loot.field_beast"]` |
| `stop_after_match` | `false` |

`ModuleBootstrap` 默认注册 `DeathLootService`。敌人死亡时：

```text
HealthComponent.die()
  -> CombatEvents.ENTITY_DIED
  -> DeathLootService 匹配 DeathLootRuleDefinition
  -> LootService.roll_table()
  -> LootEvents.LOOT_DROPPED
```

mkit 到这里为止只负责 **roll 出结果并发事件**。物品进背包、掉到地上、弹 UI、播放音效都属于你的游戏逻辑。监听 `loot_dropped` 后决定交付方式：

```gdscript
# res://game/main.gd（在 _ready 中追加）
Mkit.events().subscribe(LootEvents.LOOT_DROPPED, _on_loot_dropped)


func _on_loot_dropped(event: DomainEvent) -> void:
    var drop := event.payload.get("drop") as LootDropResult
    if drop == null or drop.roll_result == null:
        return
    var player := get_tree().get_first_node_in_group("player")
    var inventory := EntityContract.get_controller(player, "InventoryController") as InventoryController
    if inventory == null:
        return
    for item in drop.roll_result.item_instances:
        inventory.add_item(item)  # ItemInstance：definition_id + 已 roll 好的 quantity
```

`roll()` 每次先用 `ConditionEvaluator` 过滤 entries（条件失败的不进掉落池），再把 `empty_weight`（若 `allow_empty`）与各 entry 的 `weight` 加总抽签；选中后在 `min_quantity..max_quantity` 间随机数量。`drop.roll_result.debug_rolls` 记录每次 roll 的明细，调概率时直接 print 它。

## 运行验证

1. 清空房间 → 弹出奖励界面，列出 3 个选项的 `display_name` + `description`
2. 点选"治疗药剂" → 玩家 `HealthComponent.current_hp` 增加（Remote 面板查看）
3. 控制台可见 `reward_selected` 事件（`EventService.recent_events`）
4. 选择后界面关闭，加载下一个房间
5. 没有 UIManager 时（调试退化路径）：自动选第一个并继续
6. （做了步骤 7）杀敌后 `LootEvents.LOOT_DROPPED` 触发，背包出现 `item.beast_hide` / `item.beast_fang`；`drop.roll_result.debug_rolls` 可见每次 roll 的权重明细

## 字段参考

### RewardDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `reward_id` | String | ContentService 注册与查询用的稳定 id | 必填，全局唯一（见步骤 1）|
| `display_name` | String | 选项按钮标题等 UI 文案，不参与规则 | 见步骤 1 |
| `description` | String | 面向玩家的说明文本，UI 展示用 | 见步骤 1 |
| `icon` | Texture2D = null | 奖励图标；mkit 不读取，随 `RewardOption.icon` 透传给你的 UI 渲染（参考 [Recipe 18](18_ui_hud.md)）| 自绘奖励卡片时 |
| `rarity` | String = "common" | 稀有度字符串；随 `RewardOption.rarity` 透传，供 UI 样式（描边颜色等）使用，内置抽取逻辑不读取 | UI 想按稀有度区分样式时 |
| `weight` | float = 1.0 | `generate_options()` 无放回抽取的权重，越大越常出现；0 = 不会被自然抽中 | 见步骤 1 |
| `conditions` | Array[Condition] = [] | 生成选项前求值，任一失败则该奖励不进候选池（如"持有钥匙才出现宝箱奖励"）| 奖励要按条件出现时，详见 [Recipe 21](21_conditions.md) |
| `effects` | Array[GameEffect] = [] | 玩家选中后按顺序执行；**全部成功**才推进房间 | 见步骤 1 |

### LootTableDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `loot_table_id` | String | ContentService 注册与查询用的稳定 id，`roll_table()` 按它找表 | 必填，全局唯一（见步骤 7）|
| `rolls` | int = 1 | 抽取次数；每次独立按权重 roll，互不影响 | 想一次掉多件时调大 |
| `entries` | Array[LootEntry] = [] | 可被抽取的条目；条目 `conditions` 失败时本次 roll 被过滤 | 见步骤 7 |
| `allow_empty` | bool = true | 是否允许单次 roll 空手而归；关闭后 `empty_weight` 被忽略，每次必出一项 | 保底掉落设 false |
| `empty_weight` | float = 0.0 | "什么都不掉"作为一个权重项参与抽签；默认 0 即开着 `allow_empty` 也必出 | 想控制空手概率时（见步骤 7）|

### LootEntry

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `content_id` | String | 掉什么；通常指向 `ItemDefinition` 的 content id | 必填（见步骤 7）|
| `weight` | float = 1.0 | 随机权重，越大越容易掉；0 = 不会被自然选中 | 见步骤 7 |
| `min_quantity` / `max_quantity` | int = 1 / 1 | 掉落数量的随机区间（含两端）；写反了会自动交换 | 材料类掉落给区间 |
| `conditions` | Array[Condition] = [] | 每次 roll 前求值，失败则本条目不进掉落池（如"困难难度才掉稀有材料"）| 详见 [Recipe 21](21_conditions.md) |

### DeathLootRuleDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `rule_id` | String = "" | ContentService 注册用的稳定 id | 必填，全局唯一（见步骤 7）|
| `enabled` | bool = true | 关闭后规则不参与死亡匹配 | 临时禁用某套掉落规则 |
| `priority` | int = 0 | 多条规则同时匹配时高优先级先处理 | 需要先处理 boss / 特殊事件规则时 |
| `entity_definition_ids` | Array[String] = [] | 非空时只匹配这些 `EntityIdentity.definition_id` | 由 `EntitySpawner` 生成的敌人，推荐用它精确匹配 |
| `factions` | Array[String] = [] | 非空时只匹配这些死亡实体阵营 | 所有敌方单位共享一张基础掉落表 |
| `required_tags` | Array[String] = [] | 非空时死亡实体必须包含全部 tag | 按 `"beast"` / `"undead"` / `"elite"` 分类掉落 |
| `excluded_tags` | Array[String] = [] | 非空时死亡实体包含任一 tag 则排除 | 排除召唤物、训练假人等 |
| `conditions` | Array[Condition] = [] | 额外死亡上下文条件；失败则本规则不匹配 | 按难度、区域、任务状态控制掉落 |
| `loot_table_ids` | Array[String] = [] | 匹配后依次 roll 的 `LootTableDefinition` id | 一只敌人可同时掉材料表、装备表 |
| `stop_after_match` | bool = false | 本规则匹配后是否停止处理后续低优先级规则 | boss 专属表不想叠加普通敌人表时 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 清空房间后直接进下一间，不弹界面 | `reward_pool_ids` 为空，或 `reward_count <= 0` | 给 `RoomDefinition` 填 reward id；`reward_count` 保持 > 0 |
| 弹界面但没有选项按钮 | reward id 未注册，`generate_options` 返回空 | 确认 `RewardDefinition` 已入库；id 拼写一致 |
| 选了之后房间不推进 | 某个 effect 返回失败（`apply_selected` 全成功才推进）| 看 `EffectService.recent_results`；常见是 `GrantItemEffect` 找不到背包 |
| `RewardSelectionUI` 报错找不到 `OptionContainer` | 子节点名不对 | 子节点必须精确命名 `OptionContainer` |
| 货币奖励没生效 | `AddCurrencyEffect` 字段非 `@export`，`.tres` 里填不进去 | 用代码构造该 effect，或改用 `ProgressionService.add_currency` |

## 延伸阅读

- [LootService ref](../generated/html/classes/LootService.html) — roll_table / generate_options / apply_selected
- [DeathLootService ref](../generated/html/classes/DeathLootService.html) · [DeathLootRuleDefinition ref](../generated/html/classes/DeathLootRuleDefinition.html) · [LootDropResult ref](../generated/html/classes/LootDropResult.html)
- [RewardDefinition ref](../generated/html/classes/RewardDefinition.html) · [RewardOption ref](../generated/html/classes/RewardOption.html)
- [LootTableDefinition ref](../generated/html/classes/LootTableDefinition.html) · [LootEntry ref](../generated/html/classes/LootEntry.html) · [LootRollResult ref](../generated/html/classes/LootRollResult.html)
- [pipeline.md — Loot Roll](../pipeline.md#14-loot-roll)
- [cookbook/22_enemy_death_loot.md](22_enemy_death_loot.md) — 杀死敌人触发掉落
- [cookbook/23_upgrade_choice_rewards.md](23_upgrade_choice_rewards.md) — 升级三选一 reward
- [cookbook/14_shop.md](14_shop.md) — 用 `LootRollResult` 之外的方式获取物品（购买）
