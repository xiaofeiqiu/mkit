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

## 本篇路径

### Minimal path：XP、货币和存读档直接调组件 / 服务

1. 先按步骤 1 创建 `ExperienceCurve`，再按步骤 2 把 `ExperienceComponent` 挂到玩家身上。
2. 在玩家脚本 `_ready()` 里缓存组件并连接升级信号：

```gdscript
var xp := EntityContract.get_component(self, "ExperienceComponent") as ExperienceComponent
xp.level_up.connect(func(old_level: int, new_level: int): print("level up ", new_level))
```

3. 测试给经验时直接调用：

```gdscript
xp.add_xp(50)
Mkit.progression().add_currency("gold", 25)
```

4. 在主场景输入脚本里绑定保存 / 读取：

```gdscript
if event.is_action_pressed("quick_save"):
    Mkit.save().save_game(get_tree().root)
elif event.is_action_pressed("quick_load"):
    Mkit.save().load_game(get_tree().root)
```

5. 验证方式：加 XP 能触发升级，按保存键生成 `user://save.json`，改血量或货币后读取能恢复。

这条路径没有实体意图，也不需要状态机：不要把存档按钮包装成 `GameCommand` 或 `GameAction`。

### Standard path：UI / 系统输入自己调用服务

1. 如果玩家按键只是打开存档、背包或升级面板，先用 Recipe 18 注册 UI screen，例如 `"save_menu"`。
2. 输入脚本只打开面板：

```gdscript
Mkit.ui().open_screen("save_menu", {"root": get_tree().root}, true)
```

3. 面板按钮回调里调用 `Mkit.save().save_game(root)`、`Mkit.save().load_game(root)` 或 `Mkit.progression()`。
4. 面板关闭后刷新 HUD，确认货币、等级、任务状态和实体组件都来自读取结果。
5. 只有“让某个实体执行攻击、互动、施法”这类行为时才交给 `CommandReceiver`；存档和货币按钮不是实体行为。

### Advanced path：持久化边界走 EntitySaveAgent / save scope

1. 在玩家实体下加 `EntitySaveAgent`，`entity_id` 填稳定 id，例如 `"player"` 或 `"player_001"`。
2. 把 HP、背包、技能冷却、装备、位置等实体局部状态做成玩家子树里的 `SaveableComponent`，由 agent 写进 `entities.<player_id>.components`。
3. 任务、货币、经验组件这类全局系统状态保持为 `Saveable` root，写进 `roots`。
4. 只有世界区域、run/room/reward 这类“当前场景树可能还没加载，但仍要恢复”的系统，才用 save scope。
5. 保存后打开 `user://save.json` 检查：玩家组件应在 `entities` 下，不要再出现另一套玩家聚合 root。

## 关键认知：roots 存全局，entities 存实体组件

- `Saveable`（`extends Node`）：`SaveService.save_game(root)` 会收集场景树中的 `Saveable` 并按 `get_save_id()` 写入 `roots`；通过 scope 可在场景树缺失时恢复世界/奖励状态。`QuestService`、`ProgressionService`、`ExperienceComponent` 都是 `Saveable`，开箱即存。
- `EntitySaveAgent`（`extends Node`）：挂在实体下，按稳定 `entity_id` 写入 `entities[entity_id]`，并收集该实体下的组件。
- `SaveableComponent`（`extends Node`）：`HealthComponent`、`AbilityController`、`InventoryController`、`StatsComponent` 等都是它。它**有相同的 `to_save_data()` 接口，但不会被 `SaveService` 当作全局 root 收集**。要持久化它们，实体下必须有一个 `EntitySaveAgent`。

用所有权来选入口：全局系统状态进 `roots`，实体局部状态进 `entities`，没有稳定场景根但需要跨场景恢复的系统切片才注册 `scopes`。不要为了保存玩家再写一个外部 `Saveable` 去手动收集 `Components/` 和 `Controllers/`；玩家位置、姿态、朝向这类特殊状态也应做成实体下的小型 `SaveableComponent` 或 duck participant。

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
    PositionSaveComponent
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

如果玩家位置也要随实体存档，把位置封装成实体内组件，例如 `PositionSaveComponent extends SaveableComponent`，`get_save_key()` 返回 `"Position"`，`to_save_data()` / `from_save_data()` 读写 owner 的 `global_position`。这样位置和 HP、背包一样由同一个 `EntitySaveAgent` 收集。

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

## 字段参考

### Saveable

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `save_id` | String | 写入 `roots` 的 key；留空时回退到 owner（或自身）节点名 | 必填思维对待：多角色/多实例时务必各自唯一（见步骤 2）|
| `save_scope` | String = "" | 存档分组名；空 = `"global"`。同 scope 的 payload 写入 `scopes.<scope>`，读档时按 scope 局部恢复——场景树缺失（还没进那个区域）也能先把数据灌回注册的 provider | 世界/区域状态想独立于全局恢复时（如 `"zone:village"`）|
| `restore_order` | int = 0 | 读档时的恢复顺序，**数值小的先恢复** | B 的恢复依赖 A 已就位时，给 A 更小的值（如 ProgressionService 先于依赖货币的 UI 状态）|

### EntitySaveAgent

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `entity_id` | String | 写入 `entities` 的 key，必须稳定且唯一 | 见步骤 4 |
| `scene_path` | String = "" | 实体场景路径（`res://...tscn`），随存档记录，供实体重建 | 见步骤 4 |
| `zone_id` | String = "" | 实体所属 `ZoneDefinition` id，随存档记录，供按区域恢复 | 见步骤 4 |
| `root_path` | NodePath = "" | 收集组件的子树根；**留空取 owner**（整个实体场景）。agent 从这棵子树收集 `SaveableComponent` | agent 没挂在实体场景内，或只想收集某个子分支时显式指定 |
| `restore_order` | int = 0 | 多个实体间的恢复顺序，小的先恢复 | 实体 A 的组件状态被实体 B 读档逻辑依赖时 |
| `include_duck_participants` | bool = true | 是否收集加入 `ENTITY_SAVE_PARTICIPANT_GROUP` group 的 duck-typed 节点（步骤 4 的 `StanceState` 写法）| 想只认 `SaveableComponent`、屏蔽 group 成员时关掉 |

### SaveService

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `save_path` | String = "user://save.json" | 存档文件路径；写入时先写 `.tmp` 再原子替换 | 多存档槽：按槽位换路径（如 `user://save_%s.json`）|
| `save_version` | int = 1 | **应用层**存档版本号，原样写入 envelope；mkit 不解释它，供你的游戏做迁移或显示 | 你的存档内容结构变更时自增 |
| `schema_version` | int = 2 | **mkit 结构**版本（roots/entities/scopes 布局）；读档时校验，旧版本走内置迁移，比 `CURRENT_SCHEMA_VERSION` 新则拒载 | 不要改，跟随 mkit |
| `game_version` | String = "0.1.0" | 游戏版本字符串，原样写入 envelope，排查跨版本存档问题用 | 跟随你的发版号 |
| `profile_id` | String = "profile_001" | 档案 id，原样写入 envelope；配合 `save_path` 实现多档案 | 多玩家档案系统：切换档案时一起换 `save_path` |

> envelope 即 `user://save.json` 顶层结构：`schema_version / save_version / game_version / timestamp / profile_id / roots / entities / scopes`。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 背包/HP/技能没存上 | 它们是 `SaveableComponent`，没被实体 agent 收集 | 用步骤 4 的 `EntitySaveAgent` 收集；确认 `entity_id` 唯一 |
| 读档后组件数据没回来 | `get_save_key()`（节点 name）与存档 key 不一致 | 别在运行时改组件节点名；存读用同一棵子树 |
| 玩家保存逻辑出现两套 | 同时用了实体内 `EntitySaveAgent` 和外部 `Saveable` 聚合器 | 删除外部玩家聚合器，把特殊状态改成实体内 `SaveableComponent` |
| 两个全局状态串台 | `Saveable.save_id` 重复 | 每个 `Saveable` 的 `save_id` 全局唯一 |
| 两个实体串台 | `EntitySaveAgent.entity_id` 重复 | 每个长期实体的 `entity_id` 在 `entities` 内唯一 |
| 升级不触发 | `ExperienceComponent.curve` 为空或已满级 | 配好 `curve`；`current_level < max_level` 才吃 XP |
| 启动没自动载入 | 存档路径不一致，或文件不存在 | 确认 `SaveService.save_path` 与实际写入路径一致 |
| 读档把基础属性改乱 | `StatsComponent` 存的是相对 baseline 的覆盖 | spawn 后调过 `mark_save_baseline()`；别在存档后又改 base_stats baseline |

## 延伸阅读

- [SaveService ref](../generated/html/classes/SaveService.html) — save_game / load_game
- [Saveable ref](../generated/html/classes/Saveable.html) · [EntitySaveAgent ref](../generated/html/classes/EntitySaveAgent.html) · [SaveableComponent ref](../generated/html/classes/SaveableComponent.html) — root / entity / component 的差异
- [ExperienceComponent ref](../generated/html/classes/ExperienceComponent.html) · [ProgressionService ref](../generated/html/classes/ProgressionService.html)
- [pipeline.md — Save / Load](../pipeline.md#13-save--load) · [pipeline.md — Progression / Level Up](../pipeline.md#17-progression--level-up)
- [concepts.md — 存档](../concepts.md#六存档roots--entities--scope-provider)
