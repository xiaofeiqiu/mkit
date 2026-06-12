# Recipe 07：房间 + RunDirector 多房间序列  ·  难度 ★★★  ·  预计 35 分钟

## 本篇结束后，你的项目新增了什么

战斗发生在**房间**里。`RunDirector` 生成一条线性房间序列（`run_length` 个房间），逐个加载。进入房间时 `RoomController` 自动 spawn 敌人；玩家清空房间内所有敌人后触发 `room_cleared`，`RunDirector` 推进到下一个房间；走完最后一个房间触发 `run_finished("completed")`；玩家死亡触发 `run_finished("failed:player_died")`。

> 本篇先把"多房间推进"跑通，房间清空后**直接进下一间**（reward 池留空）。[Recipe 08](08_loot_and_rewards.md) 再接上奖励选择。

## 前置

- 需完成：[Recipe 06](06_ai_enemy.md)（敌人实体场景已就绪，会被 spawn 进房间）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 为敌人创建 `EntityDefinition` (.tres)，让 `EntitySpawner` 能按 id 实例化 | `EntitySpawner.spawn_entity()` 加载场景、注入身份、初始化属性 |
| 创建 `RoomDefinition` (.tres)，配置 `scene_path` / `enemy_spawn_ids` | `RoomLoader` 实例化房间场景，`RoomController` 按 id spawn 敌人 |
| 搭一个房间场景（`RoomController` + `Enemies` + `EntitySpawner`）| `RoomController` 监听 `entity_died`，全部清空后发 `room_cleared` |
| 在主场景挂 `RunDirector`，配 `first_floor_room_pool` / `RoomRoot` 容器 | `DungeonGenerator` 生成线性图，`RunDirector` 串联房间、处理推进/失败 |
| 调 `run_director.start_run()` | 加载首个房间，监听清空，自动进下一间 |

## 步骤

### 步骤 1：为敌人创建 EntityDefinition

`RoomController` 通过 `EntitySpawner.spawn_entity(definition_id, ...)` 生成敌人，`definition_id` 是一个 `EntityDefinition`。新建 Resource → `EntityDefinition`，存为 `res://data/entities/field_beast.tres`：

| 字段 | 值 |
|------|----|
| `entity_definition_id` | `"enemy.field_beast"` |
| `display_name` | `"野兽"` |
| `scene_path` | `"res://game/enemy/enemy_entity.tscn"`（Recipe 06 的敌人场景）|
| `default_faction` | `"enemy"` |
| `tags` | `["enemy"]` |
| `base_stats` | `{"max_hp": 60.0, "attack_power": 8.0, "defense": 0.0}` |

> `EntitySpawner` 会用 `base_stats` 覆盖敌人 `StatsComponent` 的基础值，并把 `entity_definition_id` 写进 spawn 出来的 `EntityIdentity.definition_id`——这个值在 [Recipe 10](10_quest.md) 用于匹配"击杀某种敌人"的任务目标。

把 `field_beast.tres` 加入 `ResourceDatabase.resources`。

### 步骤 2：创建 RoomDefinition

新建 Resource → `RoomDefinition`，存为 `res://data/rooms/combat_room_a.tres`：

| 字段 | 值 |
|------|----|
| `room_id` | `"room.combat_a"` |
| `scene_path` | `"res://game/rooms/combat_room.tscn"`（下一步创建）|
| `room_type` | `"combat"` |
| `enemy_spawn_ids` | `["enemy.field_beast", "enemy.field_beast"]`（spawn 两只）|
| `reward_pool_ids` | `[]`（本篇留空 → 清空后直接进下一间）|

同样加入 `ResourceDatabase.resources`。可以多复制几个（`room.combat_b` 等）让序列有变化。

### 步骤 3：搭建房间场景

新建场景 `res://game/rooms/combat_room.tscn`，根节点 `Node2D`，**子节点名字必须精确匹配**（`RoomController` 的默认导出路径依赖它们）：

```
CombatRoom  (Node2D)
├── RoomController   (RoomController)   # 名字必须是 "RoomController"，RoomLoader 按此查找
├── Enemies          (Node2D)           # enemy_container_path 默认 "../Enemies"
├── EntitySpawner    (EntitySpawner)    # entity_spawner_path 默认 "../EntitySpawner"
└── （可选）TileMap / 背景 / 碰撞墙
```

`RoomController` 的导出字段（多数留默认即可）：

- `enemy_container_path` = `"../Enemies"`（默认）
- `entity_spawner_path` = `"../EntitySpawner"`（默认）
- `spawn_positions` = `[Vector2(120, 80), Vector2(360, 80)]`（按 `enemy_spawn_ids` 顺序取，越界则 spawn 在原点）
- `reward_count` = `3`（reward 池为空时不影响）

> `room_definition_id` 不用在 Inspector 填——`RoomLoader.load_room()` 会调 `controller.setup(room_definition_id)` 自动注入。

### 步骤 4：在主场景挂 RunDirector

打开主游戏场景（玩家所在的那个），加入：

```
Main  (Node2D)
├── Player           (你的玩家实体，加入 "player" group)
├── RoomRoot         (Node2D)        # 房间将被加载进这里
└── RunDirector      (RunDirector)
```

配置 `RunDirector`：

- `first_floor_room_pool` = `["room.combat_a", "room.combat_b"]`（房间 def id 池）
- `room_scene_container_path` = `"../RoomRoot"`（默认）
- `player_group` = `"player"`
- `player_entity_id` = 玩家 `EntityIdentity.entity_id` 的值（默认 `"player_001"`；若你的玩家 id 是 `"player"`，改成 `"player"`）
- `run_length` = `3`（生成 3 个房间，从池中有放回随机抽取）

### 步骤 5：启动 Run 并监听结果

在主场景脚本里启动 run，并连上信号：

```gdscript
# res://game/main.gd
extends Node2D

@onready var _director := $RunDirector as RunDirector


func _ready() -> void:
    _director.run_started.connect(func(state: RunState) -> void:
        print("Run started: %s (seed=%d, %d rooms)" % [state.run_id, state.seed, _director.run_length])
    )
    _director.room_enter_requested.connect(func(room_id: String) -> void:
        print("Entering room: %s" % room_id)
    )
    _director.run_finished.connect(func(result: String) -> void:
        # result 为 "completed" 或 "failed:<reason>"
        print("Run finished: %s" % result)
    )

    # 固定 seed 便于复现；传 0 则用时间戳随机
    _director.start_run(12345)
```

`start_run()` 内部：校验 `first_floor_room_pool` 非空 → `RunState.create()` → 设置 `RandomService` 种子 → `DungeonGenerator.generate_linear()` 生成线性图 → `enter_next_room()` → `RoomLoader` 加载首个房间场景 → `RoomController.enter_room()` spawn 敌人。

### 步骤 6：房间清空如何推进（无需写代码，理解时序）

1. 玩家击杀房间里的敌人 → `HealthComponent.die()` → 广播 `CombatEvents.entity_died` 领域事件
2. `RoomController._on_entity_died()` 从 `active_enemies` 移除该敌人 → `check_clear_condition()`
3. `active_enemies` 空了 → `runtime.cleared = true` → `generate_reward()`（reward 池空 → 空数组）→ `room_cleared.emit()` + `WorldEvents.room_cleared` 领域事件
4. `RunDirector.on_room_cleared()` 发现 reward 选项为空 → `current_room_index += 1` → `enter_next_room()`
5. 走完最后一个房间 → `enter_next_room()` 取不到房间 → `complete_run()` → `run_finished("completed")`

## 运行验证

1. 运行主场景，控制台打印 `Run started` + `Entering room: room.combat_a`
2. `RoomRoot` 下出现房间场景，`Enemies` 下出现 2 只敌人
3. 清空敌人 → 自动加载下一个房间（`Entering room: ...` 再次打印，旧房间被 `queue_free`）
4. 清空全部 3 个房间 → `Run finished: completed`
5. 中途让玩家死亡 → `Run finished: failed:player_died`

## 字段参考

### EntityDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `entity_definition_id` | String | ContentService 注册用的稳定 id；`enemy_spawn_ids` 引用它，spawn 后写入 `EntityIdentity.definition_id` | 必填，全局唯一（见步骤 1）|
| `display_name` | String = "" | UI 显示名，不参与注册 | 见步骤 1 |
| `scene_path` | String = "" | 实体场景路径（`res://...tscn`），`EntitySpawner` 按它实例化 | 必填（见步骤 1）|
| `default_faction` | String = "neutral" | spawn 时写入 `EntityIdentity.faction`，决定敌友判定与 hitbox 过滤 | 敌人 `"enemy"`（见步骤 1）|
| `tags` | Array[String] = [] | 标签集合，供条件筛选、事件追踪、UI 分组 | 见步骤 1 |
| `base_stats` | Dictionary = {} | `{stat_id: 初始值}`；spawn 时覆盖 `StatsComponent` 基础值 | 见步骤 1 |
| `starting_ability_ids` | Array[String] = [] | spawn 时注册进该实体 `AbilityController` 的技能 id；每项需已入库 | 敌人要放技能时（配合 [Recipe 05](05_ability.md)）|
| `loot_table_id` | String = "" | **预留字段，mkit 不读取**。内置掉落走 `RoomDefinition.reward_pool_ids`；可在游戏代码里读它做"按敌人种类掉落"（[Recipe 08 步骤 7](08_loot_and_rewards.md) 的 `roll_table` 改为查死亡实体的定义）| 自己接消费者时 |

### RoomDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `room_id` | String | ContentService 注册用的稳定 id；`first_floor_room_pool` 引用它 | 必填，全局唯一（见步骤 2）|
| `scene_path` | String = "" | 房间场景路径，`RoomLoader` 按它实例化 | 必填（见步骤 2）|
| `room_type` | String = "combat" | 房间类型字符串（`combat` / `shop` / `event`…），由游戏内容约定语义 | 做非战斗房间时 |
| `difficulty_rating` | int = 1 | 难度等级。**mkit 内置生成器不读取**——`DungeonGenerator.generate_linear()` 只做有放回随机；供你的选房/缩放逻辑使用（如按楼层过滤房间池、按难度加成敌人属性）| 自写选房算法时 |
| `size` | Vector2i = (1, 1) | 房间逻辑尺寸。**mkit 不读取**，供布局/地图/生成约束使用 | 自写布局算法时 |
| `tags` | Array[String] = [] | 标签集合。**mkit 不读取**，供条件筛选与自定义房间池过滤 | 自写选房算法时 |
| `enemy_spawn_ids` | Array[String] = [] | 进房时 spawn 的 `EntityDefinition` id 列表，重复 id = 多只；按 `spawn_positions` 顺序落点 | 见步骤 2 |
| `reward_pool_ids` | Array[String] = [] | 清房后供三选一抽取的 `RewardDefinition` 或奖励池 id；空 = 直接进下一间 | 本篇留空，[Recipe 08](08_loot_and_rewards.md) 填上 |

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `Run finished: failed:empty_room_pool` | `first_floor_room_pool` 为空或 id 拼错 | 填入已注册的 `room_id` |
| 房间加载失败 `failed:missing_room_scene:...` | `RoomDefinition.scene_path` 指向的场景不存在 | 检查路径；场景已保存 |
| `failed:room_missing_controller` | 房间场景里没有名为 `RoomController` 的子节点 | 子节点名必须精确是 `RoomController` |
| 敌人没出现 | `EntitySpawner` 找不到 `EntityDefinition` | 确认 `field_beast.tres` 已入库；`enemy_spawn_ids` 用的是 `entity_definition_id` 不是场景路径 |
| 清空敌人后不推进 | 敌人死亡没发 `entity_died`，或 spawn 出的敌人没进 `active_enemies` | 敌人需有 `HealthComponent`（`destroy_on_death` 可选）；由 `EntitySpawner` spawn 才会登记 |
| 一进房间就 `failed:player_died` | `player_entity_id` 配错，匹配到了别的实体 | 设为玩家 `EntityIdentity.entity_id` 的真实值 |

## 延伸阅读

- [RunDirector ref](../generated/html/classes/RunDirector.html) — start_run / enter_next_room / select_reward / fail_run
- [RoomController ref](../generated/html/classes/RoomController.html) — spawn_enemies / check_clear_condition / generate_reward
- [EntitySpawner ref](../generated/html/classes/EntitySpawner.html) — spawn_entity 注入身份与属性
- [pipeline.md — Room / Run](../pipeline.md#18-room--run)
- [cookbook/08_loot_and_rewards.md](08_loot_and_rewards.md) — 房间清空后弹出奖励选择
