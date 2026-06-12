# Recipe 23：升级三选一 Reward  ·  难度 ★★☆  ·  预计 25 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

清空房间后不再只给固定奖励，而是弹出三个升级选项：攻击强化、生命强化、技能强化等。玩家选一个，mkit 执行该 `RewardDefinition.effects`，然后 `RunDirector` 继续进入下一间。

这篇讲的是 roguelite 常见的“本局内升级三选一”。它使用 `RewardDefinition` 做选择项，使用 `GameEffect` 真正改玩家。`UpgradeDefinition` 适合持久升级树或 meta progression；如果只是房间奖励里的临时升级，不需要先创建 `UpgradeDefinition`。

## 前置

- 需完成：[Recipe 07](07_room.md)（房间清空后能推进）
- 推荐完成：[Recipe 08](08_loot_and_rewards.md)（已经接入 `RewardSelectionUI`）
- 若升级要改属性，玩家需要 `StatsComponent`（见 [Recipe 03](03_health_and_stats.md)）

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 3 个以上 `RewardDefinition`，每个代表一个升级选项 | `LootService.generate_options()` 按权重无放回抽出 `RewardOption` |
| 在 `RewardDefinition.effects` 里放升级效果 | `RewardSystem.apply_selected()` 逐个执行 effect，全部成功后发 `reward_selected` |
| 给房间的 `reward_pool_ids` 填 reward id | `RoomController` 清房后生成 reward options |
| 监听 `RunDirector.choosing_reward` 并显示 UI | `RunDirector` 等玩家选择，选完后推进到下一房间 |
| 可选：监听 `LootEvents.REWARD_SELECTED` 记录本局升级 | mkit 只发选择事件，不规定你的升级记录格式 |

## 本篇路径

### Minimal path：直接测试一个升级效果

1. 先按步骤 1 创建 `res://data/effects/upgrade_attack_effect.tres`，类型为 `ApplyStatModifierEffect`。
2. 测试脚本拿到玩家节点后构造上下文：

```gdscript
var ctx := GameplayContext.from_nodes(player, player)
```

3. 直接执行效果：

```gdscript
Mkit.effects().execute(upgrade_attack_effect, ctx)
```

4. 检查玩家 `StatsComponent.get_stat_value("attack_power")` 是否增加。
5. 这条路径用于验证单张 reward 的效果；普通同步效果不需要 `GameAction`。

### Standard path：UI button 选择 reward

1. 按步骤 2 创建 3 个 `RewardDefinition`，并把它们加入 `ResourceDatabase`。
2. 复用 Recipe 08 的 `RewardSelectionUI`，它会为每个 `RewardOption` 创建按钮。
3. 主场景连接 `RunDirector.choosing_reward`，打开 UI：

```gdscript
func _on_choosing_reward(options: Array[RewardOption]) -> void:
    Mkit.ui().open_screen("reward_selection", {
        "options": options,
        "run_director": _run_director,
    }, true)
```

4. 玩家点击按钮时，UI 直接调用 `run_director.select_reward(option)`。
5. 验证方式：选中“剑刃强化”后攻击力增加，UI 关闭并进入下一房间。

UI 选择不是实体行为，不需要 `CommandReceiver` 或 `CommandService`。

### Advanced path：房间清空后等待三选一再推进

1. 打开参与本局的 `RoomDefinition`，把 `reward_pool_ids` 填成 3 个升级 reward id。
2. `RoomController` 清房后生成 reward options；`RunDirector` 不立即加载下一间，而是发 `choosing_reward(options)`。
3. UI 用 modal screen 显示三张卡，暂停 run 推进。
4. 玩家选择后，`select_reward(option)` 执行 `RewardDefinition.effects`；全部成功后 `RunDirector` 才加载下一间。
5. 如果某个 reward 本身需要前摇、可取消或跨帧表现，再把那张 reward 的具体行为做成 `GameAction`；三选一选择流程本身不需要 action。

## 关键认知：RewardDefinition 与 UpgradeDefinition 不同

| 类型 | 用途 | 什么时候用 |
|------|------|------------|
| `RewardDefinition` | “三选一里出现的一张卡” | 房间清空、宝箱、事件奖励，让玩家从几个选项里选一个 |
| `UpgradeDefinition` | “可购买或可解锁的升级节点” | 技能树、meta 升级、花货币购买、需要等级和前置校验 |
| `RunState.temporary_upgrade_ids` | 本局内已拿过哪些升级的记录 | UI 展示、存档恢复、避免重复奖励、结算统计 |

最直接的三选一升级做法：`RewardDefinition.effects` 直接放 `ApplyStatModifierEffect`。如果还要记录“玩家选过这个升级”，再监听 `LootEvents.REWARD_SELECTED`。

## 步骤

### 步骤 1：创建升级效果资源

三个示例升级：

| 升级 | effect 类型 | 关键字段 |
|------|-------------|----------|
| 剑刃强化 | `ApplyStatModifierEffect` | `stat_id="attack_power"`, `operation=FLAT_ADD`, `value=5`, `apply_to_source=true`, `duration=-1` |
| 生命核心 | `ApplyStatModifierEffect` | `stat_id="max_hp"`, `operation=FLAT_ADD`, `value=20`, `apply_to_source=true`, `duration=-1` |
| 快速步伐 | `ApplyStatModifierEffect` | `stat_id="move_speed"`, `operation=FLAT_ADD`, `value=30`, `apply_to_source=true`, `duration=-1` |

保存为：

```text
res://data/effects/upgrade_attack_effect.tres
res://data/effects/upgrade_vitality_effect.tres
res://data/effects/upgrade_speed_effect.tres
```

这些 effect 是普通 `Resource`，不需要加入 `ResourceDatabase.resources`；只有 `RewardDefinition` 需要入库。

### 步骤 2：创建 3 个 RewardDefinition

新建 Resource → `RewardDefinition`：

| 字段 | 攻击强化 | 生命强化 | 速度强化 |
|------|----------|----------|----------|
| `reward_id` | `"reward.upgrade.attack"` | `"reward.upgrade.vitality"` | `"reward.upgrade.speed"` |
| `display_name` | `"剑刃强化"` | `"生命核心"` | `"快速步伐"` |
| `description` | `"+5 attack_power"` | `"+20 max_hp"` | `"+30 move_speed"` |
| `rarity` | `"common"` | `"common"` | `"common"` |
| `weight` | `1.0` | `1.0` | `1.0` |
| `effects` | `[upgrade_attack_effect]` | `[upgrade_vitality_effect]` | `[upgrade_speed_effect]` |

把三个 `RewardDefinition` 加入 `ResourceDatabase.resources`。

### 步骤 3：把三选一池挂到房间

打开参与本局的 `RoomDefinition`，填：

```gdscript
reward_pool_ids = [
    "reward.upgrade.attack",
    "reward.upgrade.vitality",
    "reward.upgrade.speed",
]
```

`RoomController.reward_count` 默认是 3。池里正好 3 个 reward 时，三张都出现；池里多于 3 个时，`LootService.generate_options()` 会按 `weight` 无放回抽 3 个。

### 步骤 4：显示选择 UI

如果已经按 [Recipe 08](08_loot_and_rewards.md) 做了 `RewardSelectionUI`，只需要在本局入口连接：

```gdscript
func _ready() -> void:
    _run_director.choosing_reward.connect(_on_choosing_reward)


func _on_choosing_reward(options: Array[RewardOption]) -> void:
    var ui := Mkit.ui()
    if ui == null:
        if not options.is_empty():
            _run_director.select_reward(options[0])
        return
    ui.open_screen("reward_selection", {"options": options, "run_director": _run_director}, true)
```

玩家点击后：

```text
RewardSelectionUI
  -> RunDirector.select_reward(option)
  -> RewardCoordinator.apply_reward()
  -> LootService.apply_selected()
  -> RewardDefinition.effects
  -> LootEvents.REWARD_SELECTED
  -> RunDirector 进入下一房间
```

### 步骤 5：记录本局升级（可选）

如果 UI、存档或结算需要知道“本局拿过哪些升级”，监听 `reward_selected`，把 reward id 映射为你的升级 id：

```gdscript
const REWARD_TO_UPGRADE := {
    "reward.upgrade.attack": "upgrade.run.attack",
    "reward.upgrade.vitality": "upgrade.run.vitality",
    "reward.upgrade.speed": "upgrade.run.speed",
}


func _ready() -> void:
    Mkit.events().subscribe(LootEvents.REWARD_SELECTED, _on_reward_selected)


func _on_reward_selected(event: DomainEvent) -> void:
    var reward_id := str(event.payload.get("reward_id", ""))
    var upgrade_id := str(REWARD_TO_UPGRADE.get(reward_id, ""))
    if upgrade_id == "" or _run_director == null or _run_director.run_state == null:
        return
    if not _run_director.run_state.temporary_upgrade_ids.has(upgrade_id):
        _run_director.run_state.temporary_upgrade_ids.append(upgrade_id)
```

这个记录是游戏侧语义。mkit 不会规定升级 id 怎么命名，也不会把三选一 reward 自动写进 `UpgradeDefinition`。

### 步骤 6：需要永久升级时怎么接

如果玩家选择 reward 后要购买 / 解锁一个 `UpgradeDefinition`，有两种做法：

| 需求 | 做法 |
|------|------|
| 选择后必须满足货币、前置、等级上限，失败则不推进房间 | 写一个自定义 `GameEffect`，在 `_apply_impl()` 里调用 `Mkit.progression().unlock_or_level_up(upgrade_id, context)`，失败时返回失败 |
| 选择 reward 已经成功，只是顺便记录 meta 解锁 | 监听 `LootEvents.REWARD_SELECTED`，再调用 `ProgressionService`；但此时房间推进不会被该调用失败阻止 |

直接用内置升级树时，参考 [Recipe 19](19_xp_and_upgrades.md)。三选一 reward 和升级树可以共享同一套 id 命名，但不要假设 `RewardDefinition` 会自动执行 `UpgradeDefinition`。

## 运行验证

1. 清空房间后弹出三个升级选项。
2. 选择“剑刃强化”后，玩家 `StatsComponent` 的 `attack_power` 增加。
3. `EventService.recent_events` 中出现 `reward_selected`，payload 的 `reward_id` 是选中的 reward。
4. 如果做了步骤 5，`run_state.temporary_upgrade_ids` 包含对应升级 id。
5. 选择完成后，`RunDirector` 进入下一间。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 清房后没有三选一 | `RoomDefinition.reward_pool_ids` 为空，或 reward 没入库 | 把 `RewardDefinition` 加入 `ResourceDatabase.resources`，并检查 id 拼写 |
| 三选一少于 3 个 | `reward_count=3` 但候选不足，或条件过滤掉了部分 reward | 保证池里至少 3 个条件通过的 `RewardDefinition` |
| 选择后不进下一间 | 某个 effect 返回失败 | 看 `EffectService.recent_results`；属性效果通常是没找到玩家 `StatsComponent` |
| 属性没加到玩家身上 | effect 没有 `apply_to_source=true`，或 `RewardCoordinator` 找不到 player group | 玩家加入 `"player"` group，effect 指向 source |
| 记录了升级但效果没生效 | `temporary_upgrade_ids` 只是记录，不会自动改属性 | 真正升级效果必须放在 `RewardDefinition.effects` 或自定义 effect 里 |

## 延伸阅读

- [RewardDefinition ref](../generated/html/classes/RewardDefinition.html) · [RewardOption ref](../generated/html/classes/RewardOption.html)
- [RunDirector ref](../generated/html/classes/RunDirector.html) · [RoomController ref](../generated/html/classes/RoomController.html) · [RunState ref](../generated/html/classes/RunState.html)
- [ApplyStatModifierEffect ref](../generated/html/classes/ApplyStatModifierEffect.html) · [ProgressionService ref](../generated/html/classes/ProgressionService.html) · [UpgradeDefinition ref](../generated/html/classes/UpgradeDefinition.html)
- [Recipe 08](08_loot_and_rewards.md) — 房间清空后的 reward UI
- [Recipe 19](19_xp_and_upgrades.md) — XP、技能点和持久升级树
