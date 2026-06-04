# Save / Load 设计:实体状态持久化 + 世界快照层

> 本文件设计 code review 指出的存档系统两大缺口的解决方案,配套 [`spec/rpg-modules.md`](rpg-modules.md) / [`spec/rpg-impl-plan.md`](rpg-impl-plan.md) 使用。
> 设计文档讲"怎么设计、为什么这样分层";落地清单与勾选去 `rpg-impl-plan.md` 新增的对应 milestone。
> 标识符 / 代码 / 路径一律英文,概念叙述中文。

---

## 0. 现状与问题(为什么要做)

当前 `addons/mkit/kernel/save/` 的存档只够支撑 roguelike 的"元进度"切片,离完整 RPG 还差两层。摘录 code review 结论:

1. **实体运行时状态根本没进存档。** `SaveManager._collect_saveables()` 只收集 `node is Saveable` 的节点,而全仓只有 4 个类 `extends Saveable`:`ProgressionSystem` / `QuestSystem` / `AudioManager` / `ExperienceComponent`。`HealthComponent` / `StatsComponent` / `ResourcePoolComponent` / `StatusEffectController` / `AbilityController` / `InventoryController` / `EquipmentController` 全部 `extends Node`——其中 `InventoryController` / `ResourcePoolComponent` / `ItemInstance` 甚至已写好 `to_save_data` / `from_save_data`,却因不是 `Saveable` 而被跳过。结果:背包、装备、当前 HP、属性修正、技能冷却、身上的状态效果——存档时全丢。
2. **不能重建世界。** `SaveManager._restore_saveables()` 只对**树里已存在**的同名节点回灌,既不切场景也不实例化实体。玩家在哪张地图、站在哪、动态生成的敌人 / NPC / 已开宝箱 / 已击杀 Boss / 世界开关——全没存。配套缺口:单文件单槽(`save_path` 写死 `user://save.json`)、非原子写(`FileAccess.WRITE` 直接截断,无备份)、`CloudSaveService` 与 `SaveManager` 完全没桥接、`Saveable.get_save_id()` 回退 `owner.name` 会在同名实体间相互覆盖。

本设计把"存档"重构成**三层 payload + 双层职责**:Kernel 的 `SaveManager` 只负责文件 / 格式 / 版本 / 原子写 / 槽位;Module 的 `SaveCoordinator` 负责编排 globals + player + world 三段的采集与(异步)恢复。守住 `kernel 不依赖 module` 的单向依赖。

---

## 1. 总体模型:三层 payload

`save_version` 升到 `2`,磁盘文件结构:

```jsonc
{
  "header": {                         // 不读 payload 即可枚举(给读档菜单用)
    "save_version": 2,
    "game_version": "0.1.0",
    "timestamp": "2026-06-03T...",
    "playtime_seconds": 7421,
    "summary": { "zone_name": "...", "player_level": 12, "screenshot": "user://..." }
  },
  "payload": {
    "globals": { "<saveable_id>": { ... } },   // 单例 service:progression / quest / audio
    "player":  { ...EntitySnapshot... },        // 玩家实体,跨 zone 随身携带
    "world":   { ...WorldSnapshot... }          // 当前 zone + 各 zone 快照 + flags
  }
}
```

三段语义与责任划分:

| 段 | 内容 | 采集 / 恢复方 | 何时恢复 |
|---|---|---|---|
| `globals` | 与场景无关的单例状态:meta 货币 / 升级、任务日志、音量 | `SaveManager` 走既有 `is Saveable` 树遍历 | 读档**立即**同步恢复 |
| `player` | 玩家实体的组件状态(HP / 属性 / 背包 / 装备 / 技能 / 状态 / 经验) | `EntitySaver`(实体聚合器) | 切到目标 zone、玩家就位后恢复 |
| `world` | 当前 zone id + 玩家落点 + 各 zone 的动态实体清单与 flags | `WorldStateStore` | 切场景后逐 zone 重建 |

**分层红线**:`SaveManager`(kernel)只认 `header` / `payload` 两个 dict 和"in-tree `Saveable` 节点",对 player / world / entity **一无所知**;world / entity 重建这种需要上引 module 的逻辑,全部落在 module 层的 `SaveCoordinator`。

---

## 2. Part 1 — 实体运行时状态进存档

### 2.1 组件序列化契约:`SaveableComponent`(kernel/save)

新增 `addons/mkit/kernel/save/saveable_component.gd`,与既有 `Saveable` 平行,但语义是"挂在实体下、由聚合器收集的子状态",而非顶层节点:

```gdscript
class_name SaveableComponent
extends Node


func get_save_key() -> String:
    return name


func to_save_data() -> Dictionary:
    return {}


func from_save_data(data: Dictionary) -> void:
    pass
```

选 formal base class 而非 `has_method("to_save_data")` 鸭子判定,理由:与 `Saveable` 对称、聚合器可用 `child is SaveableComponent` 强类型筛选、可被 `tools/strip_comments` 体系一致对待。各组件由 `extends Node` 改成 `extends SaveableComponent`——`SaveableComponent extends Node`,故 `is Node`、`get_node(... ) as XxxComponent`、`.tscn`(按 UID 引脚本)全部不受影响。

### 2.2 各组件的 save 形状

只持久化**无法从 Definition / Content 重算**的运行时增量;能从 `ContentRegistry` 重建的(技能定义、物品定义、属性公式)只存 id 与增量。

| 组件 | `to_save_data()` 字段 | 备注 |
|---|---|---|
| `HealthComponent` | `{ current_hp, dead }` | `max_hp` 由 stats 重算,不存 |
| `StatsComponent` | `{ base_overrides, persistent_modifiers: [StatModifier] }` | **只存永久来源 modifier**,临时 buff 不存(见 2.5) |
| `ResourcePoolComponent` | `current_values`(已具备) | 改基类即可 |
| `StatusEffectController` | `active: [{ status_id, stacks, remaining_duration, source_id }]` | 读档按 id 从 content 取 definition 重新 `apply_status`,自然重挂临时 stat modifier |
| `AbilityController` | `{ learned: [ability_id], cooldowns: { ability_id: remaining } }` | definition 由 content 重建;只存学会了哪些 + 冷却剩余 |
| `InventoryController` / `ItemInstance` | 已具备(`{capacity, items[]}` / 单 item) | 改基类即可 |
| `EquipmentController` | `{ slots: { slot_id: ItemInstance } }` | 复用 `ItemInstance.to_save_data` |
| `ExperienceComponent` | `{ current_level, current_xp }`(已具备) | 由 `Saveable` 迁成 `SaveableComponent`(见 2.6) |

### 2.3 实体聚合器:`EntitySaver` + `EntitySnapshot`

per-entity 不再让每个组件各做一个顶层 `Saveable`(会撑爆扁平命名空间、且 `owner.name` 碰撞)。改为**每个需要持久化的实体挂一个聚合器节点** `EntitySaver`,把该实体 `Components/` 与 `Controllers/` 下所有 `SaveableComponent` 收成**一个**按实体 id 命名的嵌套块。

`addons/mkit/modules/entity/entity_saver.gd`:

```gdscript
class_name EntitySaver
extends Node


func capture() -> Dictionary:                         # 产出 EntitySnapshot
    var components: Dictionary = {}
    for node in _collect():                            # owner 下 Components/ + Controllers/
        if node is SaveableComponent:
            components[(node as SaveableComponent).get_save_key()] = node.to_save_data()
    return {
        "persistent_id": _persistent_id(),
        "definition_id": _definition_id(),             // EntityIdentity.definition_id
        "position": _position(),                       // owner.global_position(若 Node2D)
        "components": components,
    }


func restore(snapshot: Dictionary) -> void:
    var components: Dictionary = snapshot.get("components", {})
    for node in _collect():
        if node is SaveableComponent:
            var key := (node as SaveableComponent).get_save_key()
            if components.has(key):
                node.from_save_data(components[key])
```

**`EntitySnapshot` 是实体持久化的统一单元**:`{ persistent_id, definition_id, position, components }`。两条路径都产出 / 消费它——

- **玩家**(单一、作者放置、跨 zone):直接 capture/restore,存进 `payload.player`。
- **动态实体**(敌人 / 可拾取物):capture 进 `payload.world.zones[zone_id].entities[]`,进 zone 时由 `EntitySpawner` 重建(见 3.3)。

### 2.4 稳定唯一 id:`EntityIdentity.persistent_id`(修 save_id 碰撞)

`EntityIdentity._ready()` 现在对空 id 生成 `"%s_%d" % [name, ticks_usec()]`——**每次运行都变**,不能做存档 key。新增一个**作者可填、稳定**的持久 id,与运行时 `entity_id` 分离:

```gdscript
# entity_identity.gd 追加
@export var persistent_id: String = ""     // 作者填(玩家、命名 NPC、固定摆放物)
```

`EntitySaver._persistent_id()` 取值优先级:`persistent_id`(作者填) → spawner 注入的 runtime id → **报警告并放弃持久化**(绝不再回退 `owner.name`,从根上杜绝碰撞)。动态实体的 `persistent_id` 由 `WorldStateStore` 在首次快照时分配并写进 `ZoneSnapshot`,重建时经 `EntitySpawner.spawn_entity(..., runtime_id)` 注入(该参数已存在)。

### 2.5 关键:`StatsComponent` 临时 modifier 不直接存

`StatsComponent.modifiers_by_stat` 里混着两类来源:

- **永久来源**:reward / meta upgrade / 装备词缀(`remaining_duration <= 0`,即无限时长)。
- **临时来源**:status effect 施加的 buff/debuff(有 `remaining_duration`,`source_id == status instance_id`)。

临时 modifier **不进 `StatsComponent` 的存档**——它们会在 `StatusEffectController` 读档重新 `apply_status` 时被 `_apply_stat_modifiers` 重新挂上;若两边都存就会**重复叠加**。因此:

- `StatsComponent.to_save_data()` 只序列化 `remaining_duration <= 0`(永久)的 modifier。
- 临时 buff 的恢复完全交给 `StatusEffectController` 的 `active[]`(含 `remaining_duration`)。

恢复顺序固定为:`StatsComponent`(永久 modifier + base) → `StatusEffectController`(重挂临时 modifier) → `HealthComponent`(`current_hp` 在 `max_hp` 已就绪后 clamp)。`EntitySaver.restore` 按此固定次序遍历。

### 2.6 单例 saveable 保持顶层;`ExperienceComponent` 迁移

`ProgressionSystem` / `QuestSystem` / `AudioManager` 是**单例 service**(不绑场景实体),继续作为 `payload.globals` 里的顶层 `Saveable`,**不动**。唯一的破坏性改动是 `ExperienceComponent`:它是 per-entity 状态,从 `extends Saveable` 改成 `extends SaveableComponent`,数据从顶层 `experience` key 移到 `payload.player.components.ExperienceComponent`。用 `save_version` 1→2 的 `SaveMigration` 搬迁(框架已支持、已有测试覆盖迁移路径)。

---

## 3. Part 2 — 世界快照层

### 3.1 数据模型:`WorldSnapshot` / `ZoneSnapshot`

```gdscript
# WorldSnapshot
{
  "current_zone_id":   "zone.town",
  "current_spawn_id":  "from_dungeon",      // 优先用 spawn,落点更稳;无则退 player_position
  "player_position":   { "x": .., "y": .. },
  "global_flags":      { "met_elder": true, "act": 2 },   // 跨 zone 剧情开关
  "zones": {
    "zone.town":    { ...ZoneSnapshot... },
    "zone.dungeon": { ...ZoneSnapshot... }
  }
}

# ZoneSnapshot
{
  "flags":       { "door_north_open": true, "chest_03_looted": true },  // 本 zone 开关
  "entities":    [ ...EntitySnapshot... ],         // 该 zone 内"存活的持久动态实体"
  "removed_ids": [ "npc.guard_a", "enemy.boss_01" ] // 作者放置但已被消灭 → 进 zone 时删掉
}
```

### 3.2 谁来持有:`WorldStateStore`(modules/world,Saveable 单例)

新增 `addons/mkit/modules/world/world_state_store.gd`,`extends Saveable`,注册成 `payload.globals` 的一员(`save_id = "world"`),内存里维护 `zone_states: Dictionary`。它在玩家**离开**一个 zone 前 `capture_zone(zone_id)`(把当前场景里持久动态实体 + flags 抓快照存进 `zone_states`),**进入**一个 zone 后由 `SaveCoordinator` 调 `restore_zone(zone_id, parent)` 重建。与既有 `WorldRouter` 协作:监听 `WorldRouter.zone_changed`,在切换瞬间对**离开的 zone** 做 `capture_zone`。

`to_save_data()` = `{ current_zone_id, current_spawn_id, player_position, global_flags, zones }`;`from_save_data()` 反之,只把数据塞进内存,**不触发场景重建**(重建是异步流程,见 3.4)。

### 3.3 动态实体重建:`EntitySpawner` round-trip

存档与读档是 `EntityDefinition -> EntitySpawner -> EntityRoot` 这条既有链路的正反两半:

- **capture**:遍历当前场景中带 `EntitySaver` 且标记为 persistent 的实体,逐个 `EntitySaver.capture()` 得到 `EntitySnapshot`。作者放置、已被销毁的实体记进 `removed_ids`。
- **restore**:对目标 zone 的每个 `EntitySnapshot`,
  ```gdscript
  var entity := spawner.spawn_entity(snap.definition_id, parent, snap.position, snap.persistent_id)
  (entity.get_node("EntitySaver") as EntitySaver).restore(snap)
  ```
  `EntitySpawner.spawn_entity(definition_id, parent, position, runtime_id)` 已具备所需的全部入参(含注入持久 id),无需改签名。`removed_ids` 用于把"作者在 zone 场景里摆好、但存档时已死"的实体在重建后移除。

### 3.4 异步、scene-aware 的 LOAD 流程(核心新增)

今天的 `load_game` 假设"节点已在树里",对世界重建不成立——切场景在 Godot 里是延迟到帧末的。新增一条**多帧、异步**的读档主线,由 `SaveCoordinator` 驱动:

```
SaveCoordinator.load_game(slot):
  1. payload := SaveManager.read_payload(slot)          # 读文件 + 跑 migration(同步)
  2. SaveManager.restore_globals(root, payload.globals) # progression/quest/audio 立即恢复
  3. world_store.from_save_data(payload.world)          # 仅入内存
  4. player_snapshot := payload.player                  # 暂存,待场景就绪
  5. WorldRouter.go_to_zone(world_store.current_zone_id, world_store.current_spawn_id)
        └─ SceneRouter.change_scene(...)  →  scene_changed(延迟到帧末才真正换树)
  6. await get_tree().process_frame  (或复用 WorldRouter 既有 deferred + retry 模式)
  7. 场景就绪后:
       a. world_store.restore_zone(current_zone_id, scene_root)   # 重建动态实体 + 套 flags
       b. 定位 player(player_group)→ EntitySaver.restore(player_snapshot)
       c. WorldRouter.place_player_at_spawn(current_spawn_id)      # 或落到 player_position
  8. EventRouter.emit_save_loaded(slot)                  # UI / audio / HUD resync
```

时序要点:第 5 步 `change_scene` 之后**不能立刻**找 spawn point / player(新场景还没进树),必须等一帧——复用 `WorldRouter._finalize_zone_entry` 已经在用的 `call_deferred + retry` 范式,保持一致。

### 3.5 编排者:`SaveCoordinator`(module service `save_coordinator`)

为什么需要它、为什么不塞进 kernel `SaveManager`:完整 RPG 存读档要**依赖 world / entity / scene(都是 module 层)**,而 kernel 不允许上引 module。于是把"游戏级存读档编排"放到 module 层的 `SaveCoordinator`,kernel `SaveManager` 退化为纯文件 / 格式服务。

`addons/mkit/modules/persistence/save_coordinator.gd`,注册 `save_coordinator`:

```gdscript
class_name SaveCoordinator
extends Node

# save_game(slot):  组装 payload = { globals, player, world } → SaveManager.write_payload
# load_game(slot):  见 3.4 的异步主线
# 依赖(全部向下 / 同层,经 ServiceRegistry 或 class ref 取得):
#   - SaveManager (id "save")        — 文件 / 格式 / 槽位 / 原子写
#   - SceneRouter (id "scenes")      — 切场景
#   - WorldRouter (id "world")       — zone 切换 + 玩家落点
#   - WorldStateStore                — zone 快照存取
#   - EntitySpawner / EntitySaver / EntityIdentity (class) — 实体重建
#   - ContentRegistry (id "content") — definition 查询
```

跨 module 的 class 引用(`SaveCoordinator` → `EntitySpawner`/`EntityIdentity`)在本仓已有先例(`inventory_controller.gd` 直接引 `EntityIdentity`),属可接受;能走 `ServiceRegistry` 的优先走 service。`game_bootstrap.gd._load_profile()` 改为:若注册了 `save_coordinator` 就调它(异步、世界感知),否则退回 `SaveManager.load_game`(向后兼容老 demo)。游戏侧(如 `phase5_save_slice`)的存读档入口也从 `SaveManager` 切到 `save_coordinator`。

### 3.6 Kernel `SaveManager` 加固

把 `SaveManager` 从"单文件 + 扁平 Saveable"升级成通用文件 / 格式 / 槽位服务,**不掺入任何 world/entity 知识**:

1. **原子写 + 滚动备份。** 写到 `<path>.tmp` → `flush`/`close` → 旧档 rename 成 `<path>.bak` → tmp rename 成正式档(`DirAccess.rename`)。读档时正式档损坏 / 缺失则回退 `.bak`。杜绝写一半崩溃损档。
2. **多槽位。** 存档根目录化:`user://saves/slot_<id>.json`(+ `.bak`)。新 API:`save_to_slot(slot_id, payload)` / `read_payload(slot_id)` / `list_slots() -> Array[SaveSlotInfo]` / `delete_slot(slot_id)`。`save_game(root)` / `load_game(root)` 保留为"默认槽 + 走 Saveable 树遍历"的薄封装,老路径不破。
3. **槽位摘要 header。** `header` 段独立于 `payload`;`list_slots()` **只读 header 不解析 payload**,给读档菜单枚举(timestamp / game_version / playtime / `summary`)。`summary`(zone 名 / 角色等级名 / 截图路径)由 `SaveCoordinator` 在存档时填入。
4. **云存档桥接。** 新增 `sync_slot_to_cloud(slot_id)` / `restore_slot_from_cloud(slot_id)`:把同一份 payload dict 交给现成的 `CloudSaveService.save_to_cloud(slot, data)` / `load_from_cloud(slot)`(接口正是 `Dictionary`,无需改它)。冲突策略按 `header.timestamp` 比较,默认 last-write-wins,最终决策权留给游戏侧。
5. **类型约定。** `JSON.parse_string` 把数字全解析成 `float`;所有 `from_save_data` 对 int 字段显式 `int(...)`、float 字段 `float(...)`(现有序列化器多已遵守,补齐 `Stats`/`Status`/`Ability` 新增项)。
6. **失败信号。** 复用既有 `save_failed` / `load_failed`,补 IO error / 备份回退 / 槽位不存在的 reason 字符串。

---

## 4. 分层与依赖校验

落地前必须自检,确保没引入反向边:

```
game/ (phase 切片 / demo)
  → save_coordinator (module/persistence)
      → SaveManager (kernel)              ✅ module → kernel
      → SceneRouter / ContentRegistry (kernel services)  ✅
      → WorldRouter / WorldStateStore (module/world)      ✅ 同层
      → EntitySpawner / EntitySaver / EntityIdentity (module/entity)  ✅ 同层
SaveManager (kernel) → 只认 Saveable + dict,不 import 任何 module  ✅ kernel 不上引
SaveableComponent (kernel/save) ← 各 module 组件 extends           ✅ module → kernel
```

红线复查:① `addons/mkit/` 内无具体游戏内容(zone 名 / 敌人 id / 槽位数全来自 data 或调用方参数);② kernel 不出现任何 module class 名;③ 新增 `.gd` 全部 comment-free + 强类型 + 生成 `.uid`。

---

## 5. 落地顺序(milestone 化,doc + unit + integration 三件套)

按 `rpg-impl-plan.md` 的交付规则,每步代码 / 测试 / 文档同批交付,跑出真实 `make ut*` / `make int` 结果再勾选。建议拆成两大阶段六小步:

| 步骤 | 内容 | 关键产物 |
|---|---|---|
| **P1-a** | `SaveableComponent` 基类 + 把 Health/Stats/ResourcePool/Status/Ability/Inventory/Equipment 改基类并补 `to_save_data`(注意 2.5 临时 modifier 规则) | `kernel/save/saveable_component.gd` + 各组件 |
| **P1-b** | `EntitySaver` + `EntitySnapshot` 形状 + `EntityIdentity.persistent_id` + 恢复次序 | `modules/entity/entity_saver.gd`、`entity_identity.gd` |
| **P1-c** | `ExperienceComponent` 迁 `SaveableComponent` + `save_version` 1→2 migration | `save/save_migration` 子类、迁移测试 |
| **P2-a** | `SaveManager` 加固:原子写 / 备份 / 多槽位 / header / `list_slots` / cloud bridge | `kernel/save/save_manager.gd`、`save_slot_info.gd` |
| **P2-b** | `WorldStateStore` 快照(zone flags + 动态实体)+ `EntitySpawner` round-trip | `modules/world/world_state_store.gd` |
| **P2-c** | `SaveCoordinator` 异步 load 主线 + `game_bootstrap` 接线 + 端到端 integration | `modules/persistence/save_coordinator.gd`、bootstrap |

每步同时更新 `docs/ref/<NewClass>.md`(概念说明 / 设计目的 / 文件 / 接口 / 函数使用场景 / 使用示例)、`docs/module_layer.md`(新增 `persistence` domain + world 扩展)、`docs/pipeline.md`(新增 **Save / Load Pipeline** 段)。

---

## 6. 进度追踪(Implementation Progress)

> 实现时在此打勾,与 `spec/rpg-impl-plan.md` 同一套约定。**doc + unit + integration 三者齐全且对应 `make ut*` / `make int` 全绿,该子步才算 `[x]`;缺文档只能标 ⚠️。**
>
> - `[ ]` 未实现 · `[x]` 已实现且三件套齐全并通过 · ⚠️ 代码与测试已绿但文档欠账 · 🔄 正在做(同一时间只标一项)
> - 每步收尾把真实 `make ut*` / `make int` 结果贴进该步「验证」行。

### 进度总览

| 步骤 | 内容 | 进度 | 状态 |
|---|---|---|---|
| P1-a | `SaveableComponent` + 各组件序列化 | 0 / 10 | ☐ 未开始 |
| P1-b | `EntitySaver` + `persistent_id` + 恢复次序 | 0 / 5 | ☐ 未开始 |
| P1-c | `ExperienceComponent` 迁移 + save_version 1→2 | 0 / 5 | ☐ 未开始 |
| P2-a | `SaveManager` 加固(原子写 / 槽位 / header / cloud) | 0 / 8 | ☐ 未开始 |
| P2-b | `WorldStateStore` 快照 + `EntitySpawner` round-trip | 0 / 6 | ☐ 未开始 |
| P2-c | `SaveCoordinator` 异步 load + 接线 + 端到端 | 0 / 9 | ☐ 未开始 |

**依赖顺序**:`P1-a → P1-b → P1-c → P2-a → P2-b → P2-c`。P1-a/P1-b 是其余一切的地基;P2-c 依赖前五步全部就绪。

### P1-a — `SaveableComponent` + 各组件序列化

- [ ] `kernel/save/saveable_component.gd`(`extends Node`,virtual `get_save_key` / `to_save_data` / `from_save_data`)+ `.uid`
- [ ] `HealthComponent` 改基类 + `to_save_data() = {current_hp, dead}`
- [ ] `StatsComponent` 改基类 + `to_save_data`(**只存永久来源 modifier** + `base_overrides`,见 2.5)
- [ ] `ResourcePoolComponent` 改基类(已有 `to_save_data`/`from_save_data`)
- [ ] `StatusEffectController` 改基类 + `active[] = {status_id, stacks, remaining_duration, source_id}`
- [ ] `AbilityController` 改基类 + `{learned[], cooldowns{}}`
- [ ] `InventoryController` 改基类(已有方法)
- [ ] `EquipmentController` 改基类 + `slots` 序列化(复用 `ItemInstance`)
- [ ] **unit** — 各组件 round-trip + 边界(HP clamp 到恢复后 max_hp / Stats 不序列化临时 modifier / 冷却剩余还原)
- [ ] **docs** — `docs/ref/SaveableComponent.md` + 同步各组件 ref 的「接口 / 存档行为」段
- [ ] **验证** — `make ut-modules`(贴结果)

### P1-b — `EntitySaver` + `persistent_id` + 恢复次序

- [ ] `modules/entity/entity_saver.gd`(`capture()->EntitySnapshot` / `restore(snapshot)`)+ `.uid`
- [ ] `EntityIdentity.persistent_id` 字段 + 取值优先级(作者填 → spawner 注入 → 告警放弃,**不回退 owner.name**)
- [ ] `EntitySnapshot` 形状固化 + 固定恢复次序 `Stats → Status → Health`
- [ ] **unit** — `test_entity_saver`(多组件实体 capture/restore 全等;`persistent_id` 缺失告警且跳过)
- [ ] **docs** — `docs/ref/EntitySaver.md` + `docs/ref/EntityIdentity.md` 补 `persistent_id`
- [ ] **验证** — `make ut-modules`(贴结果)

### P1-c — `ExperienceComponent` 迁移 + save_version 1→2

- [ ] `ExperienceComponent` 由 `extends Saveable` 改 `extends SaveableComponent`
- [ ] `SaveMigration` 子类:v1→v2 把顶层 `experience` key 下沉到 `payload.player.components.ExperienceComponent`
- [ ] 更新 `test_progression_save_platform_integration.gd` 受影响断言(原断言 `payload.has("experience")`)
- [ ] **unit** — migration round-trip(旧档 → 升级 → 还原等价)
- [ ] **docs** — `docs/ref/ExperienceComponent.md` 更新存档行为
- [ ] **验证** — `make ut` + `make int`(贴结果)

### P2-a — `SaveManager` 加固

- [ ] 原子写 + 滚动备份(`<path>.tmp` → rename;旧档 → `.bak`;load 损坏回退 `.bak`)
- [ ] 多槽位 `user://saves/slot_<id>.json` + `save_to_slot` / `read_payload` / `list_slots` / `delete_slot`
- [ ] `header` 段 + `SaveSlotInfo`(+ `.uid`);`list_slots()` **只读 header 不解析 payload**
- [ ] 公共 helper `write_payload` / `read_payload`(含 migration)/ `restore_globals`
- [ ] cloud bridge `sync_slot_to_cloud` / `restore_slot_from_cloud`(复用 `CloudSaveService` 的 Dictionary 接口)
- [ ] `save_game` / `load_game` 退化为"默认槽 + Saveable 树遍历"薄封装(老路径不破)
- [ ] **unit** — `test_save_manager`(原子写中断不损主档 / `list_slots` 只读 header / 多槽互不串 / cloud 往返 / 失败 reason)
- [ ] **docs** — `docs/ref/SaveManager.md` 更新 + `docs/ref/SaveSlotInfo.md`
- [ ] **验证** — `make ut-kernel`(贴结果)

### P2-b — `WorldStateStore` 快照 + `EntitySpawner` round-trip

- [ ] `modules/world/world_state_store.gd`(`extends Saveable`,`save_id = "world"`)+ `.uid`
- [ ] `capture_zone(zone_id)` / `restore_zone(zone_id, parent)` + zone `flags` + `removed_ids`
- [ ] 监听 `WorldRouter.zone_changed`,在切换瞬间对**离开的 zone** 自动 `capture_zone`
- [ ] 动态实体经 `EntitySpawner.spawn_entity(def_id, parent, pos, persistent_id)` 重建 + `EntitySaver.restore`
- [ ] **unit** — `test_world_state_store`(进出 zone 往返 / `removed_ids` 生效 / flags 往返)
- [ ] **docs** — `docs/ref/WorldStateStore.md` + `docs/module_layer.md` world 段补充
- [ ] **验证** — `make ut-modules`(贴结果)

### P2-c — `SaveCoordinator` 异步 load + 接线 + 端到端

- [ ] `modules/persistence/save_coordinator.gd`(注册 service `save_coordinator`)+ `.uid`
- [ ] `save_game(slot)` 组装三段 payload `{globals, player, world}` → `SaveManager.write_payload`
- [ ] `load_game(slot)` 异步主线(restore globals → world store → 切场景 → 等帧就绪 → 重建 + 玩家就位,见 3.4)
- [ ] `EventRouter` 新增 `save_loaded` signal + `emit_save_loaded`
- [ ] `game_bootstrap._load_profile()` 接 `save_coordinator`(未注册时回退 `SaveManager.load_game`)
- [ ] `game/demo/phase5_save_slice.gd` 存读档入口切到 `save_coordinator`
- [ ] **integration** — `test_save_world_roundtrip_integration`(进 zone → 打死动态敌人 → 捡装备 → 受伤 → 学技能触发 cd → 存档 → 清内存 → 读档 → 全量断言还原)
- [ ] **docs** — `docs/pipeline.md` 新增 **Save / Load Pipeline** 段 + `docs/module_layer.md` 新增 `persistence` domain + `spec/int-test.md` 覆盖矩阵登记
- [ ] **验证** — `make ut` + `make int`(贴结果)

---

## 7. 测试计划

**Unit**(覆盖正常 + 边界 + 失败路径 + round-trip):

- `test/unit/modules/test_*_component.gd` 各组件:`to_save_data → from_save_data` 等价;`HealthComponent` 的 `current_hp` clamp 到恢复后 `max_hp`;`StatsComponent` **不**序列化临时 modifier;`AbilityController` 冷却剩余还原。
- `test/unit/modules/test_entity_saver.gd`:多组件实体 capture/restore 全等;`persistent_id` 缺失时拒绝并告警(不回退 owner.name)。
- `test/unit/kernel/test_save_manager.gd`:原子写中断不损主档(`.bak` 可回退)、`list_slots` 只读 header、多槽位互不串、cloud bridge 往返。
- `test/unit/modules/test_world_state_store.gd`:进出 zone 的 capture/restore、`removed_ids` 生效、flags 往返。

**Integration**(开发者视角端到端,真实 `GameBootstrap` / `ServiceRegistry`):

`test/integration/test_save_world_roundtrip_integration.gd` —
进 `zone.dungeon` → 用真实战斗管线打死一个动态敌人(进 `removed_ids`)→ 捡一件装备进背包 → 受伤掉 HP → 学一个技能并触发冷却 → `SaveCoordinator.save_game(slot)` → 清空内存 / 切回菜单 → `load_game(slot)` → 断言:当前 zone、玩家落点、被杀敌人未复活、背包 / 装备、`current_hp`、技能冷却、meta 货币(globals)**全部还原**。登记进 `spec/int-test.md` 覆盖矩阵的新 **Save / Load Pipeline** 行。

---

## 7. 风险与兼容

- **破坏性格式变更**:`save_version` 1→2 + `ExperienceComponent` 顶层 `experience` key 下沉,会改动现有 `test_progression_save_platform_integration.gd` 的断言(它现在断言 `payload.has("experience")`)。需同批更新该测试并提供 migration,确保旧档可升级。
- **动态实体必须有 `definition_id`** 才能被 `EntitySpawner` 重建。纯手摆、无 `EntityDefinition` 的场景物件,要么作者补 def + `persistent_id`,要么走"作者放置 + `removed_ids`"模型(只记"被删了",不记"被造出来")。
- **玩家定位**依赖 `WorldRouter.player_group`,默认玩家实例存在于 zone 场景内并由 spawn point 落位;若游戏采用"autoload 常驻玩家"变体,`SaveCoordinator` 需改走常驻节点路径(设计上留作可配置项,不在首版强求)。
- **异步 load 的竞态**:切场景到帧末才换树,所有"找 spawn / player / 重建实体"必须 deferred + retry(复用 `WorldRouter` 既有范式),不可同步直取。
- **大存档主线程卡顿**:同步 `JSON.stringify` + 写盘在超大存档下可能掉帧;首版同步实现,后续可把序列化 / 写盘移线程(标记为 future,不在本设计范围)。
