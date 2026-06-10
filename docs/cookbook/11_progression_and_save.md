# Recipe 11：XP / 升级 / 全局存读档  ·  难度 ★★★  ·  预计 35 分钟  ·  ← 完整 RPG loop

## 本篇结束后，你的项目新增了什么

击杀敌人给玩家 XP，攒够阈值自动升级（`level_up` 信号）。游戏进度（任务、货币、玩家组件状态）能写入存档文件并读回——按一个键存档，重启游戏 `GameBootstrap` 自动载入。做完这篇，你就有了一个完整闭环：**战斗 → 房间推进 → 奖励 → NPC/任务 → 成长 → 存档**。

## 前置

- 需完成：[Recipe 10](10_quest.md)（有任务/击杀在产生事件）
- 用到的概念：[concepts.md — 存档](../concepts.md#六存档roots--entities--scope-provider)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ExperienceCurve` (.tres) 定义升级阈值 | `ExperienceComponent.add_xp()` 累计、跨级、发 `level_up` |
| 监听 `entity_died`，给玩家 `add_xp()` | — |
| 给玩家挂 `EntitySaveAgent`，设置稳定 `entity_id` | `SaveService` 收集 `Saveable` 到 `roots`，收集 `EntitySaveAgent` 到 `entities`，并写入 scope 用于缺场景树恢复 |
| 按键调 `save_game()` / `load_game()` | `GameBootstrap` 启动时若有存档自动 `load_game()` |

## 关键认知：roots 存全局，entities 存实体组件

- `Saveable`（`extends Node`）：`SaveService.save_game(root)` 会收集场景树中的 `Saveable` 并按 `get_save_id()` 写入 `roots`；通过 scope 可在场景树缺失时恢复世界/奖励状态。`QuestService`、`ProgressionService`、`ExperienceComponent` 都是 `Saveable`，开箱即存。
- `EntitySaveAgent`（`extends Node`）：挂在实体下，按稳定 `entity_id` 写入 `entities[entity_id]`，并收集该实体下的组件。
- `SaveableComponent`（`extends Node`）：`HealthComponent`、`AbilityController`、`InventoryController`、`StatsComponent` 等都是它。它**有相同的 `to_save_data()` 接口，但不会被 `SaveService` 当作全局 root 收集**。要持久化它们，实体下必须有一个 `EntitySaveAgent`。

> 这是最常踩的坑：单独挂一个 `InventoryController` 不会进存档。下面步骤 4 给出标准实体收集模式。

## 步骤

### 步骤 1：创建 ExperienceCurve

新建 Resource → `ExperienceCurve`，存为 `res://data/progression/main_curve.tres`：

| 字段 | 值 | 说明 |
|------|----|----|
| `max_level` | `20` | 满级后不再吃 XP |
| `base_xp` | `100` | 公式法首级所需 |
| `growth_factor` | `1.5` | 每级所需 = `base_xp * growth_factor^(level-1)` |
| `xp_thresholds` | `[]` | 留空走公式；想精确控制可逐级填 `Array[int]` |

### 步骤 2：给玩家挂 ExperienceComponent

在玩家实体下加 `ExperienceComponent`（`extends Saveable`）：

- `curve` = `res://data/progression/main_curve.tres`
- `starting_level` = `1`
- `save_id` = `"experience"`（留空会自动设为 `"experience"`；多角色时务必各自唯一）

> `ExperienceComponent` 本身是 `Saveable`，会被 `SaveService` 单独收集到 `roots`，不依赖步骤 4 的实体 agent。

### 步骤 3：击杀 → 给 XP，并监听升级

`ExperienceComponent` 不会自己监听击杀，需要你接线。在玩家脚本里：

```gdscript
# 挂在玩家实体上的脚本
func _ready() -> void:
    var xp := EntityContract.get_component(self, "ExperienceComponent") as ExperienceComponent
    if xp == null:
        return
    xp.level_up.connect(func(old_level: int, new_level: int):
        print("升级！%d → %d" % [old_level, new_level])
        # 这里可以加属性、播特效等
    )

    var events := Mkit.events()
    if events != null:
        events.subscribe(CombatEvents.ENTITY_DIED, _on_entity_died.bind(xp))


func _on_entity_died(event: DomainEvent, xp: ExperienceComponent) -> void:
    # 只有敌人给经验（payload 自带 faction）
    if event.payload.get("faction", "") == "enemy":
        xp.add_xp(20)
```

`add_xp()` 内部累计，跨过 `curve.get_xp_required(level)` 阈值时自增等级并发 `level_up`，溢出的 XP 结转到下一级。

### 步骤 4：给玩家挂 EntitySaveAgent，收集组件

在玩家实体下加一个 `EntitySaveAgent` 子节点：

```text
Player
  Components/
    HealthComponent
    StatsComponent
  Controllers/
    AbilityController
    InventoryController
  EntitySaveAgent
```

Inspector 设置：

| 字段 | 值 | 说明 |
|------|----|----|
| `entity_id` | `"player"` | 稳定实体 id，在 `entities` 内唯一 |
| `scene_path` | `"res://game/entities/player.tscn"` | 可选，用于后续实体重建 |
| `zone_id` | `"village"` | 可选，用于世界/区域恢复 |

`get_save_key()` 默认返回组件节点 `name`，所以玩家子树里每个组件节点名要唯一（`HealthComponent`、`AbilityController`…天然唯一）。这样 HP、技能冷却、背包、属性 modifier 会进入 `entities.player.components`。

如果某个节点因为单继承限制不能 `extends SaveableComponent`，但也要随实体存档，显式加入 group 并实现 duck-typed 接口：

```gdscript
extends Node

var stance: String = "normal"

func _ready() -> void:
    add_to_group(EntitySaveAgent.ENTITY_SAVE_PARTICIPANT_GROUP)

func get_save_key() -> String:
    return "StanceState"

func to_save_data() -> Dictionary:
    return {"stance": stance}

func from_save_data(data: Dictionary) -> void:
    stance = str(data.get("stance", "normal"))
```

### 步骤 5：触发存档 / 读档

`ProgressionService` 已是全局 `Saveable`，货币与升级开箱即存。绑两个键：

```gdscript
# 任意常驻脚本（如主场景）
func _unhandled_input(event: InputEvent) -> void:
    var save := Mkit.save()
    if save == null:
        return
    if event.is_action_pressed("quick_save"):
        if save.save_game(get_tree().root):
            print("已存档 → %s" % save.save_path)
    elif event.is_action_pressed("quick_load"):
        if save.load_game(get_tree().root):
            print("已读档")
```

`save_game(root)` 收集 `root` 子树 `Saveable`（`QuestService`、`ProgressionService`、`ExperienceComponent`、`AudioService`…）写入 `roots`，收集 `EntitySaveAgent` 写入 `entities`，并写入 `scopes` 字段（默认 `user://save.json`）。

### 步骤 6：启动自动载入

无需额外代码：`GameBootstrap._load_profile()` 在 boot 流程里，若 `save.save_path` 文件存在就自动 `load_game(tree.root)`。所以下次启动游戏，进度自动回到上次存档点。

## 运行验证

1. 杀敌 → 控制台累计 XP；攒够 → `升级！1 → 2`
2. 接任务、攒货币、消耗技能后按 `quick_save` → 生成 `user://save.json`
3. 把玩家打残血、清空背包，按 `quick_load` → HP / 背包 / 任务进度 / 等级全部回到存档时
4. 关掉游戏重开 → `GameBootstrap` 自动载入，进度还在
5. 打开 `user://save.json`（`%APPDATA%/Godot/app_userdata/...`）能看到 `roots.progression`、`roots.experience`、`entities.player.components` 等字段

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 背包/HP/技能没存上 | 它们是 `SaveableComponent`，没被实体 agent 收集 | 用步骤 4 的 `EntitySaveAgent` 收集；确认 `entity_id` 唯一 |
| 读档后组件数据没回来 | `get_save_key()`（节点 name）与存档 key 不一致 | 别在运行时改组件节点名；存读用同一棵子树 |
| 两个全局状态串台 | `Saveable.save_id` 重复 | 每个 `Saveable` 的 `save_id` 全局唯一 |
| 两个实体串台 | `EntitySaveAgent.entity_id` 重复 | 每个长期实体的 `entity_id` 在 `entities` 内唯一 |
| 升级不触发 | `ExperienceComponent.curve` 为空或已满级 | 配好 `curve`；`current_level < max_level` 才吃 XP |
| 启动没自动载入 | 存档路径不一致，或文件不存在 | 确认 `SaveService.save_path` 与实际写入路径一致 |
| 读档把基础属性改乱 | `StatsComponent` 存的是相对 baseline 的覆盖 | spawn 后调过 `mark_save_baseline()`；别在存档后又改 base_stats baseline |

## 延伸阅读

- [SaveService ref](../ref/kernel/SaveService.md) — save_game / load_game
- [Saveable ref](../ref/kernel/Saveable.md) · [EntitySaveAgent ref](../ref/kernel/EntitySaveAgent.md) · [SaveableComponent ref](../ref/kernel/SaveableComponent.md) — root / entity / component 的差异
- [ExperienceComponent ref](../ref/modules/ExperienceComponent.md) · [ProgressionService ref](../ref/modules/ProgressionService.md)
- [pipeline.md — Save / Load](../pipeline.md#13-save--load) · [pipeline.md — Progression / Level Up](../pipeline.md#17-progression--level-up)
- [concepts.md — 存档](../concepts.md#六存档roots--entities--scope-provider)
