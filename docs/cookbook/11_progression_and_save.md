# Recipe 11：XP / 升级 / 全局存读档  ·  难度 ★★★  ·  预计 35 分钟  ·  ← 完整 RPG loop

## 本篇结束后，你的项目新增了什么

击杀敌人给玩家 XP，攒够阈值自动升级（`level_up` 信号）。游戏进度（任务、货币、玩家组件状态）能写入存档文件并读回——按一个键存档，重启游戏 `GameBootstrap` 自动载入。做完这篇，你就有了一个完整闭环：**战斗 → 房间推进 → 奖励 → NPC/任务 → 成长 → 存档**。

## 前置

- 需完成：[Recipe 10](10_quest.md)（有任务/击杀在产生事件）
- 用到的概念：[concepts.md — 模型 4：两条存档契约](../concepts.md#模型-4两条存档契约)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ExperienceCurve` (.tres) 定义升级阈值 | `ExperienceComponent.add_xp()` 累计、跨级、发 `level_up` |
| 监听 `entity_died`，给玩家 `add_xp()` | — |
| 写一个 `Saveable` 收集玩家的 `SaveableComponent` 们 | `SaveService` 收集场景树 `Saveable`，并写入 scope 用于缺场景树恢复 |
| 按键调 `save_game()` / `load_game()` | `GameBootstrap` 启动时若有存档自动 `load_game()` |

## 关键认知：两种存档基类，只有一种被自动收集

- `Saveable`（`extends Node`）：`SaveService.save_game(root)` 会收集场景树中的 `Saveable` 并按 `get_save_id()` 存；通过 scope 可在场景树缺失时恢复世界/奖励状态。`QuestService`、`ProgressionService`、`ExperienceComponent` 都是 `Saveable`，开箱即存。
- `SaveableComponent`（`extends Node`）：`HealthComponent`、`AbilityController`、`InventoryController`、`StatsComponent` 等都是它。它**有相同的 `to_save_data()` 接口，但不会被 `SaveService` 自动收集**。要持久化它们，必须由一个 `Saveable`（通常是玩家存档代理）主动把它们收集进来。

> 这是最常踩的坑：单独挂一个 `InventoryController` 不会进存档。下面步骤 4 给出标准收集模式。

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

> `ExperienceComponent` 本身是 `Saveable`，会被 `SaveService` 单独收集，不依赖步骤 4 的玩家代理。

### 步骤 3：击杀 → 给 XP，并监听升级

`ExperienceComponent` 不会自己监听击杀，需要你接线。在玩家脚本里：

```gdscript
# 挂在玩家实体上的脚本
func _ready() -> void:
    var xp := get_node_or_null("ExperienceComponent") as ExperienceComponent
    if xp == null:
        return
    xp.level_up.connect(func(old_level: int, new_level: int):
        print("升级！%d → %d" % [old_level, new_level])
        # 这里可以加属性、播特效等
    )

    var events := ServiceRegistry.get_service("events") as EventService
    if events != null:
        events.entity_died.connect(_on_entity_died.bind(xp))


func _on_entity_died(entity_id: String, entity_ref: Node, xp: ExperienceComponent) -> void:
    var identity := entity_ref.get_node_or_null("EntityIdentity") as EntityIdentity if entity_ref != null else null
    # 只有敌人给经验
    if identity != null and identity.faction == "enemy":
        xp.add_xp(20)
```

`add_xp()` 内部累计，跨过 `curve.get_xp_required(level)` 阈值时自增等级并发 `level_up`，溢出的 XP 结转到下一级。

### 步骤 4：写一个玩家存档代理，收集 SaveableComponent

新建脚本，挂成玩家实体的一个子节点（如 `PlayerSaveAgent`）：

```gdscript
# res://game/entities/player_save_agent.gd
class_name PlayerSaveAgent
extends Saveable
# 在 Inspector 设 save_id = "player"（全局唯一）


func to_save_data() -> Dictionary:
    var data: Dictionary = {}
    # owner = 玩家场景根；遍历其下所有 SaveableComponent
    var root := owner if owner != null else get_parent()
    for node in root.find_children("*", "", true, false):
        if node is SaveableComponent:
            var comp := node as SaveableComponent
            data[comp.get_save_key()] = comp.to_save_data()
    return data


func from_save_data(data: Dictionary) -> void:
    var root := owner if owner != null else get_parent()
    for node in root.find_children("*", "", true, false):
        if node is SaveableComponent:
            var comp := node as SaveableComponent
            var key := comp.get_save_key()  # 默认是节点 name
            if data.has(key):
                comp.from_save_data(data[key])
```

> `get_save_key()` 默认返回节点 `name`，所以玩家子树里每个组件节点名要唯一（`HealthComponent`、`AbilityController`…天然唯一）。这样 HP、技能冷却、背包、属性 modifier 全都进了同一份 `"player"` 存档。

### 步骤 5：触发存档 / 读档

`ProgressionService` 已是全局 `Saveable`，货币与升级开箱即存。绑两个键：

```gdscript
# 任意常驻脚本（如主场景）
func _unhandled_input(event: InputEvent) -> void:
    var save := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
    if save == null:
        return
    if event.is_action_pressed("quick_save"):
        if save.save_game(get_tree().root):
            print("已存档 → %s" % save.save_path)
    elif event.is_action_pressed("quick_load"):
        if save.load_game(get_tree().root):
            print("已读档")
```

`save_game(root)` 收集 `root` 子树 `Saveable`（玩家代理、`QuestService`、`ProgressionService`、`ExperienceComponent`、`AudioService`…），并写入 `scopes` 字段（默认 `user://save.json`）。

### 步骤 6：启动自动载入

无需额外代码：`GameBootstrap._load_profile()` 在 boot 流程里，若 `save.save_path` 文件存在就自动 `load_game(tree.root)`。所以下次启动游戏，进度自动回到上次存档点。

> 想加版本迁移：给 `SaveService.migrations` 配 `SaveMigration` 资源（`from_version` / `to_version` / override `_migrate_impl`），`save_version` 升级时自动按链迁移旧存档。

## 运行验证

1. 杀敌 → 控制台累计 XP；攒够 → `升级！1 → 2`
2. 接任务、攒货币、消耗技能后按 `quick_save` → 生成 `user://save.json`
3. 把玩家打残血、清空背包，按 `quick_load` → HP / 背包 / 任务进度 / 等级全部回到存档时
4. 关掉游戏重开 → `GameBootstrap` 自动载入，进度还在
5. 打开 `user://save.json`（`%APPDATA%/Godot/app_userdata/...`）能看到 `"player"`、`"quest"`、`"progression"`、`"experience"` 各键

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 背包/HP/技能没存上 | 它们是 `SaveableComponent`，没被收集 | 用步骤 4 的玩家代理收集；确认代理是 `Saveable` 且 `save_id` 唯一 |
| 读档后组件数据没回来 | `get_save_key()`（节点 name）与存档 key 不一致 | 别在运行时改组件节点名；存读用同一棵子树 |
| 两个 `Saveable` 串台 | `save_id` 重复，互相覆盖 | 每个 `Saveable` 的 `save_id` 全局唯一 |
| 升级不触发 | `ExperienceComponent.curve` 为空或已满级 | 配好 `curve`；`current_level < max_level` 才吃 XP |
| 启动没自动载入 | 存档路径不一致，或文件不存在 | 确认 `SaveService.save_path` 与实际写入路径一致 |
| 读档把基础属性改乱 | `StatsComponent` 存的是相对 baseline 的覆盖 | spawn 后调过 `mark_save_baseline()`；别在存档后又改 base_stats baseline |

## 延伸阅读

- [SaveService ref](../ref/kernel/SaveService.md) — save_game / load_game / 迁移链
- [Saveable ref](../ref/kernel/Saveable.md) · [SaveableComponent ref](../ref/kernel/SaveableComponent.md) — 两种契约的差异
- [ExperienceComponent ref](../ref/modules/ExperienceComponent.md) · [ProgressionService ref](../ref/modules/ProgressionService.md)
- [pipeline.md — Save / Load](../pipeline.md#13-save--load) · [pipeline.md — Progression / Level Up](../pipeline.md#17-progression--level-up)
- [concepts.md — 模型 4：两条存档契约](../concepts.md#模型-4两条存档契约)
