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
    var ui := ServiceRegistry.get_port(ServiceRegistry.SERVICE_UI) as UIManager
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

## 运行验证

1. 清空房间 → 弹出奖励界面，列出 3 个选项的 `display_name` + `description`
2. 点选"治疗药剂" → 玩家 `HealthComponent.current_hp` 增加（Remote 面板查看）
3. 控制台可见 `reward_selected` 事件（`EventService.recent_events`）
4. 选择后界面关闭，加载下一个房间
5. 没有 UIManager 时（调试退化路径）：自动选第一个并继续

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 清空房间后直接进下一间，不弹界面 | `reward_pool_ids` 为空，或 `reward_count <= 0` | 给 `RoomDefinition` 填 reward id；`reward_count` 保持 > 0 |
| 弹界面但没有选项按钮 | reward id 未注册，`generate_options` 返回空 | 确认 `RewardDefinition` 已入库；id 拼写一致 |
| 选了之后房间不推进 | 某个 effect 返回失败（`apply_selected` 全成功才推进）| 看 `EffectService.recent_results`；常见是 `GrantItemEffect` 找不到背包 |
| `RewardSelectionUI` 报错找不到 `OptionContainer` | 子节点名不对 | 子节点必须精确命名 `OptionContainer` |
| 货币奖励没生效 | `AddCurrencyEffect` 字段非 `@export`，`.tres` 里填不进去 | 用代码构造该 effect，或改用 `ProgressionService.add_currency` |

## 延伸阅读

- [LootService ref](../ref/modules/LootService.md) — roll_table / generate_options / apply_selected
- [RewardDefinition ref](../ref/modules/RewardDefinition.md) · [RewardOption ref](../ref/modules/RewardOption.md)
- [RewardSelectionUI ref](../ref/modules/RewardSelectionUI.md) — setup(data) 的数据约定
- [pipeline.md — Loot Roll](../pipeline.md#14-loot-roll)
- [cookbook/14_shop.md](14_shop.md) — 用 `LootRollResult` 之外的方式获取物品（购买）
