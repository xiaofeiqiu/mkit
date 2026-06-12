# Recipe 15：世界区域 / Portal 跳转  ·  难度 ★★☆  ·  预计 25 分钟  ·  [扩展]

## 本篇结束后，你的项目新增了什么

玩家可以通过场景里的 `Portal` 从一个区域跳到另一个区域。每个区域由 `ZoneDefinition` 描述，`WorldService` 负责按 zone id 找到目标场景、调用 `SceneService` 换场景、把玩家放到目标 `SpawnPoint`，并在进入区域时发 `zone_changed` / `zone_entered` 事件和播放区域 BGM。

## 前置

- 需完成：[Recipe 01](01_bootstrap.md)（`GameBootstrap` + `ResourceDatabase` 在线）
- 建议完成：[Recipe 09](09_npc_dialogue.md)（玩家已有 `InteractionComponent` 和交互输入）
- 用到的概念：[pipeline.md — Scene / Zone Transition](../pipeline.md#20-scene--zone-transition)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 创建 `ZoneDefinition` (.tres)，配置区域场景、默认出生点和 BGM id | `ContentService` 按 `zone_id` 注册和查询区域 |
| 在目标场景放玩家（或能生成玩家）并把玩家加入 `"player"` group | `WorldService` 按 `player_group` 找玩家并移动到出生点 |
| 在区域场景放 `SpawnPoint`，设置匹配的 `spawn_id` | `SpawnPoint` 自动加入 `"spawn_point"` group |
| 在交互 `Area2D` 下挂 `Portal`，配置目标 zone / spawn | `Portal` 调 `WorldService.go_to_zone()`，再由 `SceneService` 换场景 |
| 可选：创建 `AudioDefinition`，让 `audio_id` 匹配 `bgm_id` | `GameBootstrap` 自动注册 BGM；`WorldService` 进入区域后播放 |

## 关键认知：纯换场景和世界区域跳转不是一回事

`SceneService.change_scene(path)` 只做场景切换，适合标题页、失败界面、重载当前关卡这类没有"世界区域"语义的跳转。

`WorldService.go_to_zone(zone_id, spawn_id)` 是 RPG / 冒险地图常用入口：它会按 `ZoneDefinition.scene_path` 切场景，切完后按 `spawn_id` 放置玩家，发区域事件，播放区域 BGM，并把当前区域写入 `world.zone` 存档 scope。

## 步骤

### 步骤 1：准备两个区域场景

先准备两个普通 Godot 场景，例如：

```
res://game/scenes/village.tscn
res://game/scenes/forest.tscn
```

每个**目标区域场景**里必须能找到一个 `Node2D` 玩家，并且玩家在 `"player"` group 中。最直接的做法是在每个区域场景都放一个玩家实体；如果你的游戏用常驻玩家，也可以在场景切换后由自己的代码把玩家重新挂回当前场景。

在 `forest.tscn` 里放一个 `SpawnPoint`：

```
Forest  (Node2D)
├── PlayerEntity  (EntityRoot / Node2D, group: "player")
├── FromVillage  (SpawnPoint)  # spawn_id = "from_village"
└── DefaultSpawn (SpawnPoint)  # spawn_id = "default"
```

`WorldService` 只看 `SpawnPoint.spawn_id`，节点名可以自定。`SpawnPoint._ready()` 会自动加入 `"spawn_point"` group。

### 步骤 2：创建 ZoneDefinition

新建 Resource → `ZoneDefinition`，存为 `res://game/resources/zones/forest_zone.tres`：

| 字段 | 值 |
|------|----|
| `zone_id` | `"zone.forest"` |
| `display_name` | `"森林"` |
| `scene_path` | `"res://game/scenes/forest.tscn"` |
| `default_spawn_id` | `"default"` |
| `bgm_id` | `"forest_theme"`（可留空）|
| `tags` | `["outdoor"]`（可留空）|

再为村庄建一个 `res://game/resources/zones/village_zone.tres`：

| 字段 | 值 |
|------|----|
| `zone_id` | `"zone.village"` |
| `display_name` | `"村庄"` |
| `scene_path` | `"res://game/scenes/village.tscn"` |
| `default_spawn_id` | `"default"` |
| `bgm_id` | `"village_theme"`（可留空）|

把两个 `ZoneDefinition` 加入 `ResourceDatabase.resources`。`zone_id` 是内容 id，必须全局唯一。

### 步骤 3：给区域配置 BGM（可选）

`GameBootstrap` 默认会注册全局 `"audio"` 服务。新建 Resource → `AudioDefinition`，存为 `res://game/resources/audio/forest_theme.tres`：

| 字段 | 值 |
|------|----|
| `audio_id` | `"forest_theme"` |
| `stream` | `res://game/audio/forest_loop.wav` |
| `kind` | `MUSIC` |
| `loop` | `true` |

把这个 `AudioDefinition` 和 `ZoneDefinition` 一起加入 `ResourceDatabase.resources`。Bootstrap 加载内容后会自动注册；进入区域时 `WorldService` 会自动：

```gdscript
audio.play_music(definition.bgm_id)
```

如果 `bgm_id` 为空、没有匹配的 `AudioDefinition`，或者没有可用 `AudioService`，区域跳转仍然正常，只是不播放 BGM。

### 步骤 4：在出发区域放 Portal

在 `village.tscn` 里放一个交互区域。它和 Recipe 09 的 NPC 交互结构一样：`InteractionComponent` 检测重叠的 `Area2D`，然后找这个 Area2D 下名为 `Interactable` 的子节点。

```
Village  (Node2D)
├── PlayerEntity  (EntityRoot / Node2D, group: "player")
├── DefaultSpawn  (SpawnPoint)  # spawn_id = "default"
└── ForestGate    (Area2D)
    ├── CollisionShape2D
    └── Interactable  (Portal)  # 名字必须是 "Interactable"
```

`Portal` 配置：

| 字段 | 值 |
|------|----|
| `target_zone_id` | `"zone.forest"` |
| `target_spawn_id` | `"from_village"` |
| `display_text` | `"前往森林"` |
| `conditions` | `[TargetInRangeCondition(condition_id="forest_gate_close", range=64.0)]` |

玩家需要有 `InteractionComponent`，并且玩家交互 Area2D 与 `ForestGate` 的 collision layer / mask 有交集。上面的 `conditions` 是二次门禁：提示范围可以做得宽一点，但真正跳转要求玩家离 `ForestGate` owner 64 像素内。`InteractionComponent.try_interact()` 构造的 context 是 `source=玩家`、`target=Portal owner`；更多条件写法见 [Recipe 21](21_conditions.md)。如果需要钥匙/任务门槛，按 Recipe 21 步骤 4 写自定义「持有钥匙」条件后挂在同一个数组里。

### 步骤 5：按交互键触发跳转

如果你已经做过 Recipe 09，输入逻辑通常已经是这样：

```gdscript
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("interact"):
        var interaction := EntityContract.get_controller(owner, "InteractionComponent") as InteractionComponent
        if interaction != null:
            interaction.try_interact()
```

`try_interact()` 会调 `Portal.interact(ctx)`，再调：

```gdscript
world.go_to_zone("zone.forest", "from_village")
```

如果 `target_zone_id` 为空、`WorldService` 未注册、zone 没入库、目标场景路径为空或正在切场景，`Portal` 会返回 `false`。

### 步骤 6：代码直接切区域

不是所有区域跳转都需要交互物。剧情脚本、任务奖励、调试面板也可以直接调：

```gdscript
func go_to_forest() -> void:
    var world := Mkit.world()
    if world == null:
        return
    if not world.go_to_zone("zone.forest", "from_village"):
        push_warning("无法进入森林")
```

需要纯粹换到某个 scene、不需要 zone 状态时，才直接用 `SceneService`：

```gdscript
var scenes := Mkit.scenes()
scenes.change_scene("res://game/scenes/title.tscn")
```

### 步骤 7：监听区域变化

`WorldService` 成功进入区域后会发本地信号，也会通过 `EventService` 发领域事件：

```gdscript
var world := Mkit.world()
if world != null:
    world.zone_changed.connect(func(from_zone_id: String, to_zone_id: String):
        print("进入区域：%s -> %s" % [from_zone_id, to_zone_id])
    )
```

可以用这个信号刷新地图名、保存安全点，或加载区域 UI。

## 运行验证

1. 启动游戏，确认 `ResourceDatabase` 中有 `"zone.village"` 和 `"zone.forest"`
2. 玩家走进 `ForestGate`，按交互键
3. 场景切到 `forest.tscn`
4. 玩家位置与 `spawn_id = "from_village"` 的 `SpawnPoint` 一致
5. `WorldService.current_zone_id == "zone.forest"`
6. `EventService.recent_events` 里有 `zone_changed` / `zone_entered`
7. 如果配置了 `bgm_id` 和匹配的 `AudioDefinition`，进入区域后 BGM 切到对应音乐
8. 调 `SaveService.save_game(root)` 后，存档 `scopes["world.zone"]["world"].current_zone_id` 写入当前区域；读档时会切回该区域场景

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| 按交互键没反应 | `Portal` 子节点没有命名为 `Interactable`，或碰撞层不相交 | 保持 `Area2D/Interactable` 结构；检查 layer / mask |
| `go_to_zone()` 返回 `false` | zone 未注册、`scene_path` 为空、`SceneService` 不在线或正在切场景 | 把 `ZoneDefinition` 加入 `ResourceDatabase`；检查 `GameBootstrap` 服务注册 |
| 切场景成功但玩家没有到出生点 | 目标场景里没有 `"player"` group 玩家，或没有匹配 `spawn_id` 的 `SpawnPoint` | 给玩家加 `"player"` group；确认 `SpawnPoint.spawn_id` 与 `target_spawn_id` 完全一致 |
| 每次都落到默认点 | `target_spawn_id` 留空，或目标 spawn id 拼错 | 明确设置 `Portal.target_spawn_id`，或改 `ZoneDefinition.default_spawn_id` |
| 没有 BGM | `ZoneDefinition.bgm_id` 为空，或没有同名 `AudioDefinition(kind=MUSIC)` 入库 | 填 `bgm_id`，并把匹配的 `AudioDefinition` 加入 `ResourceDatabase` |
| 读档没有回到正确区域 | 没用 `SaveService.save_game(root)`，或 `WorldService` 没注册 scope | 确认 `GameBootstrap` 注册 `"world"` / `"save"` 服务，且用 `SaveService` 正常存读档 |

## 延伸阅读

- [WorldService ref](../generated/html/classes/WorldService.html) — go_to_zone / place_player_at_spawn / world.zone 存档 scope
- [ZoneDefinition ref](../generated/html/classes/ZoneDefinition.html) · [SpawnPoint ref](../generated/html/classes/SpawnPoint.html) · [Portal ref](../generated/html/classes/Portal.html)
- [SceneService ref](../generated/html/classes/SceneService.html) — 纯场景切换和切换信号
- [AudioDefinition ref](../generated/html/classes/AudioDefinition.html) · [AudioService ref](../generated/html/classes/AudioService.html) — BGM id 注册与播放
- [pipeline.md — Scene / Zone Transition](../pipeline.md#20-scene--zone-transition)
