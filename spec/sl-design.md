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

**审核结论**:主体方向符合 RPG / roguelike save/load 的 common practice:版本化 envelope、稳定 id、原子写、备份、多槽位、header 摘要、迁移、world snapshot、scene-aware async load 都是正确方向。落地前还必须补齐六类 best practice 约束:① save consistency boundary(安全存档点 + 防重入);② schema / content preflight validation;③ transactional load + 失败回滚;④ portable primitive envelope 与 pluggable codec,不把 JSON 绑定成唯一生产格式;⑤ corrupt/hash 检测;⑥ slot path 安全、cloud conflict 以及 procedural RNG 边界。本文件后续章节已把这些约束并入设计与 milestone。

---

## 1. 总体模型:三层 payload

`save_version` 升到 `2`,逻辑 envelope 结构:

```jsonc
{
  "header": {                         // 不读 payload 即可枚举(给读档菜单用)
    "format": "mkit_save",
    "codec": "json",
    "save_version": 2,
    "game_version": "0.1.0",
    "slot_id": "001",
    "timestamp": "2026-06-03T...",
    "timestamp_unix": 1780500000,
    "revision": 12,
    "playtime_seconds": 7421,
    "payload_hash": "optional_md5_or_empty",
    "summary": { "zone_name": "...", "player_level": 12, "screenshot": "user://..." }
  },
  "payload": {
    "globals": { "<saveable_id>": { ... } },   // 单例 service:progression / quest / audio
    "player":  { ...EntitySnapshot... },        // 玩家实体,跨 zone 随身携带
    "world":   { ...WorldSnapshot... }          // 当前 zone + 各 zone 快照 + flags
  }
}
```

逻辑 envelope 只允许 portable primitive tree:`Dictionary` / `Array` / `String` / `bool` / `int` / `float` / `null`。`Vector2` 写成 `{ "x": float, "y": float }`,`Resource` / `Node` / `PackedScene` / `Callable` 永不直接进存档;需要引用内容时只存 `ContentRegistry` 中的 definition id。这样读档菜单、迁移、cloud sync 和损坏检测都不依赖 Godot 对象生命周期。

### 1.1 磁盘编码:`SaveCodec`

存档系统的公共模型是 versioned `Dictionary` envelope,**不是 JSON 文件本身**。`SaveManager` 负责组装 / 校验 / 迁移 envelope,再交给 `SaveCodec` 做字节编码。这样首版仍能用 JSON 保持可读、易测,但正式发行可以换成 `.sav` 二进制、压缩、加密或平台专用 blob,不需要改 gameplay save 逻辑。

新增 `addons/mkit/kernel/save/save_codec.gd` 与默认 `json_save_codec.gd`:

```gdscript
class_name SaveCodec
extends Resource


func get_format_id() -> String:
    return "json"


func get_file_extension() -> String:
    return "json"


func encode(envelope: Dictionary) -> PackedByteArray:
    return PackedByteArray()


func decode(bytes: PackedByteArray) -> Dictionary:
    return {}
```

默认 `JsonSaveCodec` 产出 UTF-8 JSON 文本,用于 debug / test / editor-friendly 存档。生产 codec 可在保持同一 envelope schema 的前提下选择:

- `JsonSaveCodec`:默认,文件后缀 `.json`,可人工检查,便于 diff 和测试。
- `CompressedSaveCodec`:后缀 `.sav`,对 JSON 或 binary payload 做压缩,降低体积。
- `EncryptedSaveCodec`:后缀 `.sav`,在压缩后加密 / 认证,用于防篡改和平台发行。
- `BinarySaveCodec`:后缀 `.sav`,用自定义二进制编码 primitive tree,减少解析开销。

`SaveManager` 在 decode 前通过自身 `codec` 配置或槽位文件扩展选择 codec;`header.codec` 是 decode 后的校验字段,用于发现"用错 codec / 文件后缀错配 / 存档被错误改写"。`header.format` 表示 logical envelope 格式(`"mkit_save"`),`header.codec` 表示实际编码(`"json"` / `"compressed"` / `"encrypted"` 等)。迁移始终发生在 decode 后的 envelope Dictionary 上。

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
| `AbilityController` | `{ learned: [ability_id], cooldowns: { ability_id: remaining }, charges: { ability_id: current }, recharge_durations: { ability_id: duration } }` | definition 由 content 重建;只存学会了哪些、冷却剩余和多充能运行时增量 |
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
        "position": _position_data(),                  // { "x": float, "y": float }
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

**`EntitySnapshot` 是实体持久化的统一单元**:`{ persistent_id, definition_id, position: {x, y}, components }`。两条路径都产出 / 消费它——

- **玩家**(单一、作者放置、跨 zone):直接 capture/restore,存进 `payload.player`。
- **动态实体**(敌人 / 可拾取物):capture 进 `payload.world.zones[zone_id].entities[]`,进 zone 时由 `EntitySpawner` 重建(见 3.3)。

### 2.4 稳定唯一 id:`EntityIdentity.persistent_id`(修 save_id 碰撞)

`EntityIdentity._ready()` 现在对空 id 生成 `"%s_%d" % [name, ticks_usec()]`——**每次运行都变**,不能做存档 key。新增一个**作者可填、稳定**的持久 id,与运行时 `entity_id` 分离:

```gdscript
# entity_identity.gd 追加
@export var persistent_id: String = ""     // 作者填(玩家、命名 NPC、固定摆放物)
```

`EntitySaver._persistent_id()` 取值优先级:`persistent_id`(作者填) → spawner 注入的 runtime id → **报警告并放弃持久化**(绝不再回退 `owner.name`,从根上杜绝碰撞)。动态实体的 `persistent_id` 由 `WorldStateStore` 在首次快照时分配并写进 `ZoneSnapshot`,重建时经 `EntitySpawner.spawn_entity(..., runtime_id)` 注入(该参数已存在)。

`EntitySpawner` 收到非空 `runtime_id` 时应同时写入 `EntityIdentity.entity_id` 与 `EntityIdentity.persistent_id`。`entity_id` 仍可作为当前运行时引用,`persistent_id` 才是跨 session 的存档 key;空 `persistent_id` 的实体视为 transient,默认不进快照。

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
  "random_state":      { "seed": 123, "state": 456 },  // procedural run 需要续同一条随机序列时保存
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
  "removed_ids": [ "authored_entity_id" ]           // 作者放置但已被移除 → 进 zone 时删掉
}
```

### 3.2 谁来持有:`WorldStateStore`(modules/world module service)

新增 `addons/mkit/modules/world/world_state_store.gd`,作为 module service 注册为 `world_state`,内存里维护 `zone_states: Dictionary`。它可以复用 `Saveable` 的 `to_save_data` / `from_save_data` 形状,但 **SaveCoordinator 必须把它写入 `payload.world`,不能混进 `payload.globals["world"]`**。`globals` 只放 progression / quest / audio 这类真正场景无关的单例,避免同一段 world state 有两个来源。

它在玩家**离开**一个 zone 前 `capture_zone(zone_id)`(把当前场景里持久动态实体 + flags 抓快照存进 `zone_states`),**进入**一个 zone 后由 `SaveCoordinator` 调 `restore_zone(zone_id, parent)` 重建。不能只监听现有 `WorldRouter.zone_changed`:当前信号在新 scene finalize 后才发,旧 scene 已经离树。需要新增 `WorldRouter.zone_will_change(from_zone_id, to_zone_id)` 或等价 pre-change hook,在 `SceneRouter.change_scene()` 之前 capture 离开的 zone;`zone_changed` 只用于 after-enter 通知。

`to_save_data()` = `{ current_zone_id, current_spawn_id, player_position, random_state, global_flags, zones }`;`from_save_data()` 反之,只把数据塞进内存,**不触发场景重建**(重建是异步流程,见 3.4)。

### 3.3 动态实体重建:`EntitySpawner` round-trip

存档与读档是 `EntityDefinition -> EntitySpawner -> EntityRoot` 这条既有链路的正反两半:

- **capture**:遍历当前场景中带 `EntitySaver` 且标记为 persistent 的实体,逐个 `EntitySaver.capture()` 得到 `EntitySnapshot`。作者放置、已被销毁的实体记进 `removed_ids`。
- **restore**:对目标 zone 的每个 `EntitySnapshot`,
  ```gdscript
  var entity := spawner.spawn_entity(snap.definition_id, parent, snap.position, snap.persistent_id)
  (entity.get_node("EntitySaver") as EntitySaver).restore(snap)
  ```
  `EntitySpawner.spawn_entity(definition_id, parent, position, runtime_id)` 已具备所需的全部入参(含注入持久 id),无需改签名。`removed_ids` 用于把"作者在 zone 场景里摆好、但存档时已死"的实体在重建后移除。

实体持久化策略必须显式,避免把普通刷怪、临时投射物或 VFX 误写进永久存档:

- `transient`:默认策略,不保存;进 zone 时按场景 / 生成器重新出现。
- `snapshot`:由 `EntitySpawner` 动态创建且需要跨读档保持的实体,存进 `entities[]`;被移除后从 `entities[]` 消失即可。
- `authored`:作者摆在 zone 场景里的固定实体,场景实例化后天然会出现;若被玩家永久移除,只把 `persistent_id` 写入 `removed_ids` 作为 tombstone。

### 3.4 异步、scene-aware 的 LOAD 流程(核心新增)

今天的 `load_game` 假设"节点已在树里",对世界重建不成立——切场景在 Godot 里是延迟到帧末的。新增一条**多帧、异步**的读档主线,由 `SaveCoordinator` 驱动:

```
SaveCoordinator.load_game(slot):
  1. envelope := SaveManager.read_envelope(slot)        # 读文件 + hash/schema 校验 + migration(同步)
  2. payload := envelope.payload
  3. SaveCoordinator.validate_payload(payload)          # 校验 zone / scene / definition / component keys
  4. load_session.begin()                               # 防重入,暂停输入,记录当前 scene + globals rollback
  5. SaveManager.restore_globals(root, payload.globals) # progression/quest/audio,此后失败需 rollback
  6. world_store.from_save_data(payload.world)          # 仅入内存,不实例化场景
  7. player_snapshot := payload.player                  # 暂存,待场景就绪
  8. WorldRouter.go_to_zone(world_store.current_zone_id, world_store.current_spawn_id)
        └─ SceneRouter.change_scene(...)  →  scene_changed(延迟到帧末才真正换树)
  9. await scene ready  (复用 WorldRouter 既有 call_deferred + retry 模式)
 10. 场景就绪后:
       a. world_store.restore_zone(current_zone_id, scene_root)   # 重建动态实体 + 套 flags
       b. 定位 player(player_group),按策略落位:
          - checkpoint / zone transition save:优先 WorldRouter.place_player_at_spawn(current_spawn_id)
          - manual / resume save:优先 player_snapshot.position 或 world_store.player_position
       c. EntitySaver.restore(player_snapshot)           # 只恢复组件状态,不要再次覆盖 player position
 11. load_session.commit()
 12. EventRouter.emit_save_loaded(slot)                  # UI / audio / HUD resync

on error after step 3:
  -> load_session.rollback_best_effort()
  -> SaveManager.load_failed.emit(slot_path, reason)
```

时序要点:第 8 步 `change_scene` 之后**不能立刻**找 spawn point / player(新场景还没进树),必须等一帧或等 `WorldRouter` finalize 完成——复用 `WorldRouter._finalize_zone_entry` 已经在用的 `call_deferred + retry` 范式,保持一致。读档失败不能留下半恢复状态;至少 globals 要能回滚,scene 回滚是 best-effort。

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
#   - WorldStateStore (id "world_state") — zone 快照存取
#   - EntitySpawner / EntitySaver / EntityIdentity (class) — 实体重建
#   - ContentRegistry (id "content") — definition 查询
```

跨 module 的 class 引用(`SaveCoordinator` → `EntitySpawner`/`EntityIdentity`)在本仓已有先例(`inventory_controller.gd` 直接引 `EntityIdentity`),属可接受;能走 `ServiceRegistry` 的优先走 service。`game_bootstrap.gd._load_profile()` 改为:若注册了 `save_coordinator` 就调它(异步、世界感知),否则退回 `SaveManager.load_game`(向后兼容老 demo)。游戏侧(如 `phase5_save_slice`)的存读档入口也从 `SaveManager` 切到 `save_coordinator`。

### 3.6 Kernel `SaveManager` 加固

把 `SaveManager` 从"单文件 + 扁平 Saveable"升级成通用文件 / 格式 / 槽位服务,**不掺入任何 world/entity 知识**:

1. **Codec 抽象。** `SaveManager` 增加 `@export var codec: SaveCodec`,默认实例为 `JsonSaveCodec`。`SaveManager` 只处理 envelope Dictionary,所有文件 bytes/text 编码都经 `codec.encode` / `codec.decode`。
2. **原子写 + 滚动备份。** 写到同目录 `<path>.tmp` → `flush`/`close` → 旧档 rename 成 `<path>.bak` → tmp rename 成正式档(`DirAccess.rename`)。读档时正式档损坏 / 缺失则回退 `.bak`。杜绝写一半崩溃损档。
3. **多槽位。** 存档根目录化:`user://saves/slot_<id>.<codec_ext>`(+ `.bak`)。默认 `JsonSaveCodec` 使用 `.json`;production codec 可使用 `.sav`。新 API:`save_to_slot(slot_id, payload, summary)` / `read_envelope(slot_id)` / `read_payload(slot_id)` / `list_slots() -> Array[SaveSlotInfo]` / `delete_slot(slot_id)`。`save_game(root)` / `load_game(root)` 保留为"默认槽 + 走 Saveable 树遍历"的薄封装,老路径不破。
4. **槽位摘要 header。** `header` 段独立于 `payload`;`list_slots()` 尽量只读 header。`JsonSaveCodec` 可轻量解析 header;生产 codec 若无法局部读取,可维护同目录 `slot_<id>.meta.json` header sidecar,避免读档菜单解码完整大存档。`summary`(zone 名 / 角色等级名 / 截图路径)由 `SaveCoordinator` 在存档时填入。
5. **云存档桥接。** 新增 `sync_slot_to_cloud(slot_id)` / `restore_slot_from_cloud(slot_id)`:默认把 envelope dict 交给现成的 `CloudSaveService.save_to_cloud(slot, data)` / `load_from_cloud(slot)`(接口正是 `Dictionary`,无需改它)。若平台需要 opaque blob,由平台 adapter 或 codec 扩展提供 bytes 通道,不把二进制细节泄漏给 gameplay。冲突策略比较 `header.revision`、`timestamp_unix` 与 `playtime_seconds`;本地和远端都更新过时不静默覆盖,把两个 header 交给游戏侧 resolver,默认策略才是 last-write-wins。
6. **类型约定。** 文本 codec decode 后可能把数字统一成 float;所有 `from_save_data` 对 int 字段显式 `int(...)`、float 字段 `float(...)`(现有序列化器多已遵守,补齐 `Stats`/`Status`/`Ability` 新增项)。二进制 codec 也必须返回同一 primitive envelope 形状。
7. **失败信号。** 复用既有 `save_failed` / `load_failed`,补 IO error / codec decode error / 备份回退 / 槽位不存在的 reason 字符串。
8. **Saveable id 碰撞检测。** `_collect_saveables` 遇到重复 `save_id` 必须 fail 或至少 emit `save_failed`,不能后写覆盖先写。顶层 globals 要求显式 `save_id`;`owner.name` fallback 只作为老 demo 兼容路径并发 warning。
9. **schema + hash 校验。** `read_envelope()` 先经 codec decode bytes,再校验 `header.format == "mkit_save"`、`header.save_version <= current`、`payload` 是 Dictionary、三段 payload 存在,再跑 migration。v1 legacy 旧档允许顶层 `save_version` / `payload` 形状,由 migration 先归一成 v2 envelope。`payload_hash` 非空时校验 payload 的 canonical sorted-key primitive hash;失败则尝试 `.bak`,两份都坏才发 `load_failed`。
10. **slot id 安全。** `slot_id` 只能匹配 `[A-Za-z0-9_-]+`,内部统一映射到 `user://saves/slot_<slot_id>.<codec_ext>`;拒绝 `/`、`\`、`..`、空白和绝对路径,避免 path traversal 或写到存档目录外。
11. **untrusted save 原则。** 存档里的 zone / entity / item / ability / status 只按 id 走 `ContentRegistry` 校验,绝不从存档 payload 直接 `load(scene_path)` 或执行脚本路径。缺失 definition 是读档失败或降级跳过的显式 reason,不能静默生成半残实体。

### 3.7 Common-practice 补强:一致性、校验、回滚

1. **安全存档点。** `SaveCoordinator.save_game(slot)` 只在 pipeline 稳定点采集:不在 `GameAction` active frame 中、不在 `EffectExecutor` 正在批量改状态时、不在 `WorldRouter` 切场景 pending 时。若玩家手动 quicksave 发生在不安全时刻,请求排队到下一帧或 zone finalize 后执行。
2. **capture 顺序。** 存档前先 `WorldStateStore.capture_zone(current_zone_id)`,再 capture player,最后 capture globals/header。这样离开当前 zone 前的动态实体和 flags 不会漏掉。
3. **防重入。** `SaveCoordinator` 维护 `is_saving` / `is_loading`;save/load 进行中拒绝或排队新的 save/load,并向 UI 发出明确失败 reason。避免两次写同一槽或 load 时又触发 autosave。
4. **preflight validation。** `SaveManager` 只校验 envelope / schema / migration;`SaveCoordinator` 校验 gameplay 引用:目标 zone 存在、zone scene 可加载、`EntitySnapshot.definition_id` 存在、组件 key 在当前实体上可恢复、物品 / 技能 / 状态 id 在 content 中存在。preflight 失败时不修改当前 runtime。
5. **transactional load。** 一旦开始应用 payload,`load_session` 记录当前 scene path 与 globals snapshot,并暂时抑制 normal zone capture / autosave hook。后续任一步失败时先恢复 globals,再尽量切回原 scene;如果 scene rollback 也失败,至少保持 ServiceRegistry 的长期状态自洽并发 `load_failed`。
6. **procedural RNG 边界。** 如果一个 zone / run 要读档后继续同一条 procedural 序列,保存 `RandomService` 的 seed + current state;如果 current state 不可用,就保存已解析出的 RoomGraph / ZoneSnapshot / loot result,不要只保存初始 seed 并假设能重放到同一点。
7. **autosave 策略。** 首版 autosave 只绑定 checkpoint/zone transition/save menu confirm 等安全点;不要按固定 timer 在战斗中硬写。后续若需要后台 autosave,先加 snapshot copy 与写盘节流,避免主线程卡顿和中途状态撕裂。

---

## 4. 分层与依赖校验

落地前必须自检,确保没引入反向边:

```
game/ (phase 切片 / demo)
  → save_coordinator (module/persistence)
      → SaveManager (kernel)              ✅ module → kernel
      → SceneRouter / ContentRegistry (kernel services)  ✅
      → WorldRouter / WorldStateStore(id "world_state") (module/world)      ✅ 同层
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
| **P2-a** | `SaveManager` 加固:`SaveCodec` / 默认 JSON codec / 原子写 / 备份 / 多槽位 / header / `list_slots` / schema+hash / slot safety / cloud bridge | `kernel/save/save_manager.gd`、`save_codec.gd`、`json_save_codec.gd`、`save_slot_info.gd` |
| **P2-b** | `WorldStateStore` 快照(zone flags + 动态实体 + tombstone + random_state)+ `EntitySpawner` round-trip | `modules/world/world_state_store.gd` |
| **P2-c** | `SaveCoordinator` 异步 load 主线 + safe point / preflight / rollback + `game_bootstrap` 接线 + 端到端 integration | `modules/persistence/save_coordinator.gd`、bootstrap |

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
| P1-a | `SaveableComponent` + 各组件序列化 | 11 / 11 | ✅ 完成 |
| P1-b | `EntitySaver` + `persistent_id` + 恢复次序 | 0 / 6 | ☐ 未开始 |
| P1-c | `ExperienceComponent` 迁移 + save_version 1→2 | 0 / 6 | ☐ 未开始 |
| P2-a | `SaveManager` 加固(codec / 原子写 / 槽位 / header / schema / cloud) | 0 / 15 | ☐ 未开始 |
| P2-b | `WorldStateStore` 快照 + `EntitySpawner` round-trip | 0 / 9 | ☐ 未开始 |
| P2-c | `SaveCoordinator` 异步 load + safe point + rollback + 端到端 | 0 / 13 | ☐ 未开始 |

**依赖顺序**:`P1-a → P1-b → P1-c → P2-a → P2-b → P2-c`。P1-a/P1-b 是其余一切的地基;P2-c 依赖前五步全部就绪。

### P1-a — `SaveableComponent` + 各组件序列化

- [x] `kernel/save/saveable_component.gd`(`extends Node`,virtual `get_save_key` / `to_save_data` / `from_save_data`)+ `.uid`
- [x] `HealthComponent` 改基类 + `to_save_data() = {current_hp, dead}`
- [x] `StatsComponent` 改基类 + `to_save_data`(**只存永久来源 modifier** + `base_overrides`,见 2.5)
- [x] `ResourcePoolComponent` 改基类(已有 `to_save_data`/`from_save_data`)
- [x] `StatusEffectController` 改基类 + `active[] = {status_id, stacks, remaining_duration, source_id}`
- [x] `AbilityController` 改基类 + `{learned[], cooldowns{}, charges{}, recharge_durations{}}`
- [x] `InventoryController` 改基类(已有方法)
- [x] `EquipmentController` 改基类 + `slots` 序列化(复用 `ItemInstance`)
- [x] **unit** — 各组件 round-trip + 边界(HP clamp 到恢复后 max_hp / Stats 不序列化临时 modifier / 多充能冷却剩余还原 / status source restore / spawned stats baseline)
- [x] **docs** — `docs/ref/SaveableComponent.md` + 同步各组件 ref 的「接口 / 存档行为」段
- [x] **验证** — `make ut`:kernel 102/102 + modules 213/213 passing;`make int`:35/35 passing

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

- [ ] `kernel/save/save_codec.gd` 抽象(`get_format_id` / `get_file_extension` / `encode` / `decode`)+ `.uid`
- [ ] `kernel/save/json_save_codec.gd` 默认实现(UTF-8 JSON,debug/test friendly)+ `.uid`
- [ ] `SaveManager.codec` 注入,所有落盘读写都经 `codec.encode` / `codec.decode`,不在 API 层绑定 JSON
- [ ] 原子写 + 滚动备份(`<path>.tmp` → rename;旧档 → `.bak`;load 损坏回退 `.bak`)
- [ ] 多槽位 `user://saves/slot_<id>.<codec_ext>` + `save_to_slot` / `read_envelope` / `read_payload` / `list_slots` / `delete_slot`
- [ ] `slot_id` 白名单校验(`[A-Za-z0-9_-]+`) + 固定目录映射,拒绝 path traversal
- [ ] `header` 段(`format` / `codec` / `revision` / `timestamp_unix` / `payload_hash` / `summary`) + `SaveSlotInfo`(+ `.uid`);`list_slots()` 优先 header-only,必要时使用 `slot_<id>.meta.json` sidecar
- [ ] `validate_envelope` + `payload_hash` 校验 + 正式档损坏自动 fallback `.bak`
- [ ] `_collect_saveables` 检测重复 `save_id`,顶层 globals 缺显式 `save_id` 发 warning,禁止静默覆盖
- [ ] 公共 helper `write_payload` / `read_payload`(含 migration)/ `restore_globals`
- [ ] cloud bridge `sync_slot_to_cloud` / `restore_slot_from_cloud`(复用 `CloudSaveService` 的 Dictionary 接口) + conflict resolver hook
- [ ] `save_game` / `load_game` 退化为"默认槽 + Saveable 树遍历"薄封装(老路径不破)
- [ ] **unit** — `test_save_manager` + codec tests(`JsonSaveCodec` round-trip / codec decode failure / 原子写中断不损主档 / `list_slots` header-only 或 sidecar / 多槽互不串 / duplicate `save_id` 失败 / corrupt hash fallback / slot_id 拒绝 / cloud 往返 / 失败 reason)
- [ ] **docs** — `docs/ref/SaveManager.md` 更新 + `docs/ref/SaveCodec.md` + `docs/ref/JsonSaveCodec.md` + `docs/ref/SaveSlotInfo.md`
- [ ] **验证** — `make ut-kernel`(贴结果)

### P2-b — `WorldStateStore` 快照 + `EntitySpawner` round-trip

- [ ] `modules/world/world_state_store.gd`(service id `world_state`,输出写入 `payload.world`)+ `.uid`
- [ ] `capture_zone(zone_id)` / `restore_zone(zone_id, parent)` + zone `flags` + `removed_ids`
- [ ] `random_state` 或 resolved procedural snapshot 持久化边界(不能只靠初始 seed 假装可重放)
- [ ] 实体 persist policy:`transient` / `snapshot` / `authored tombstone`
- [ ] `WorldRouter` 新增 `zone_will_change` 或等价 pre-change hook,在旧 scene 离树前自动 `capture_zone`;`zone_changed` 只做 after-enter 通知
- [ ] 动态实体经 `EntitySpawner.spawn_entity(def_id, parent, pos, persistent_id)` 重建 + `EntitySaver.restore`
- [ ] **unit** — `test_world_state_store`(进出 zone 往返 / `removed_ids` 生效 / flags 往返 / dynamic entity absence 不误进 tombstone / random_state 往返)
- [ ] **docs** — `docs/ref/WorldStateStore.md` + `docs/module_layer.md` world 段补充
- [ ] **验证** — `make ut-modules`(贴结果)

### P2-c — `SaveCoordinator` 异步 load + 接线 + 端到端

- [ ] `modules/persistence/save_coordinator.gd`(注册 service `save_coordinator`)+ `.uid`
- [ ] `save_game(slot)` 只在 safe point 组装三段 payload `{globals, player, world}` → `SaveManager.write_payload`
- [ ] `WorldStateStore.capture_zone(current_zone_id)` → player → globals/header 的固定 capture 顺序
- [ ] `load_game(slot)` 异步主线(read+validate → preflight → restore globals → world store → 切场景 → 等帧就绪 → 重建 + 玩家就位,见 3.4)
- [ ] `load_session` 防重入 + 抑制 normal zone capture/autosave + rollback globals/current scene best-effort
- [ ] `validate_payload` 校验 zone scene / definition ids / component keys,preflight 失败不改 runtime
- [ ] 玩家落位策略(checkpoint 用 spawn,manual/resume 用 saved position),避免 `EntitySaver.restore` 后又被 spawn 覆盖
- [ ] `EventRouter` 新增 `save_loaded` signal + `emit_save_loaded`
- [ ] `game_bootstrap._load_profile()` 接 `save_coordinator`(未注册时回退 `SaveManager.load_game`)
- [ ] `game/demo/phase5_save_slice.gd` 存读档入口切到 `save_coordinator`
- [ ] **integration** — `test_save_world_roundtrip_integration`(进 zone → 打死 authored persistent entity 进入 `removed_ids`、动态 snapshot entity 从 `entities[]` 消失 → 捡装备 → 受伤 → 学技能触发 cd → 存档 → 清内存 → 读档 → 全量断言还原)
- [ ] **docs** — `docs/pipeline.md` 新增 **Save / Load Pipeline** 段 + `docs/module_layer.md` 新增 `persistence` domain + `spec/int-test.md` 覆盖矩阵登记
- [ ] **验证** — `make ut` + `make int`(贴结果)

---

## 7. 测试计划

**Unit**(覆盖正常 + 边界 + 失败路径 + round-trip):

- `test/unit/modules/test_*_component.gd` 各组件:`to_save_data → from_save_data` 等价;`HealthComponent` 的 `current_hp` clamp 到恢复后 `max_hp`;`StatsComponent` **不**序列化临时 modifier;`AbilityController` 冷却剩余还原。
- `test/unit/modules/test_entity_saver.gd`:多组件实体 capture/restore 全等;`persistent_id` 缺失时拒绝并告警(不回退 owner.name)。
- `test/unit/kernel/test_save_manager.gd`:默认 `JsonSaveCodec` round-trip、codec decode failure、原子写中断不损主档(`.bak` 可回退)、`list_slots` header-only 或 sidecar、多槽位互不串、slot_id path traversal 拒绝、重复 `save_id` 失败、schema/hash 损坏 fallback、cloud bridge 往返与冲突 hook。
- `test/unit/modules/test_world_state_store.gd`:进出 zone 的 capture/restore、`removed_ids` 生效、flags 往返、dynamic snapshot entity 被移除后不会误写 tombstone、`random_state` 或 resolved procedural snapshot 往返。
- `test/unit/modules/test_save_coordinator.gd`:非 safe point 的 save 会排队或失败、防重入、preflight 失败不改 runtime、load 中途失败会 rollback globals。

**Integration**(开发者视角端到端,真实 `GameBootstrap` / `ServiceRegistry`):

`test/integration/test_save_world_roundtrip_integration.gd` —
进 `zone.dungeon` → 用真实战斗管线移除一个 authored persistent entity(进 `removed_ids`)并移除一个 dynamic snapshot entity(从 `entities[]` 消失)→ 捡一件装备进背包 → 受伤掉 HP → 学一个技能并触发冷却 → `SaveCoordinator.save_game(slot)` → 清空内存 / 切回菜单 → `load_game(slot)` → 断言:当前 zone、玩家落点、被移除实体未复活、背包 / 装备、`current_hp`、技能冷却、meta 货币(globals)**全部还原**。登记进 `spec/int-test.md` 覆盖矩阵的新 **Save / Load Pipeline** 行。

---

## 8. 风险与兼容

- **破坏性格式变更**:`save_version` 1→2 + `ExperienceComponent` 顶层 `experience` key 下沉,会改动现有 `test_progression_save_platform_integration.gd` 的断言(它现在断言 `payload.has("experience")`)。需同批更新该测试并提供 migration,确保旧档可升级。
- **动态实体必须有 `definition_id`** 才能被 `EntitySpawner` 重建。纯手摆、无 `EntityDefinition` 的场景物件,要么作者补 def + `persistent_id`,要么走"作者放置 + `removed_ids`"模型(只记"被删了",不记"被造出来")。
- **玩家定位**依赖 `WorldRouter.player_group`,默认玩家实例存在于 zone 场景内并由 spawn point 落位;若游戏采用"autoload 常驻玩家"变体,`SaveCoordinator` 需改走常驻节点路径(设计上留作可配置项,不在首版强求)。
- **异步 load 的竞态**:切场景到帧末才换树,所有"找 spawn / player / 重建实体"必须 deferred + retry(复用 `WorldRouter` 既有范式),不可同步直取。
- **load rollback 不是完整事务数据库**:globals 可以通过 snapshot 回滚;scene rollback 只能 best-effort。preflight 必须尽量把会失败的内容提前挡住,减少进入应用阶段后失败的概率。
- **RandomService 当前只暴露 seed**:若首版要保存 `random_state.state`,需同批扩展 `RandomService` API;否则必须保存已生成结果,不能承诺读档后继续同一条随机序列。
- **存档文件不可信**:slot id、definition id、component key、数量字段都要校验和 clamp;不要从 payload 直接读取 scene path / script path 并 `load()`。
- **cloud timestamp 可能受系统时钟影响**:`timestamp_unix` 只能作默认排序依据;跨设备冲突要结合 `revision`、`playtime_seconds` 与游戏侧 resolver。
- **大存档主线程卡顿**:同步 codec encode + 写盘在超大存档下可能掉帧;首版同步实现,后续可把 encode / 写盘移线程(标记为 future,不在本设计范围)。
