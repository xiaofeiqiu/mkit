# mkit 架构与用户体验评审（Best Practice 对照）

评审日期：2026-06-11
评审范围：`addons/mkit/`（kernel + modules）、`docs/`、`game/` demo、`Makefile` / `tools/` 工程门禁。
评审视角：架构设计是否符合业界通用实践（Godot 社区惯例、数据驱动游戏框架如 Unreal GAS / Unity ScriptableObject 模式、通用软件工程实践），以及作为框架的开发者体验（DX）。
关联评审：`reviews/ux-review.md`（2026-06-10，偏 demo 第一印象与文档导航，本文不重复其结论）。

---

## 总体结论

mkit 的骨架质量高于多数同体量的 Godot 开源 addon：单一 autoload、组合根 bootstrap、类型化门面、模块清单 + CI 分层校验、四层文档、单元/集成/冒烟三层测试，这些都是实打实落地的业界好实践。整个 addon 约 8000 行，体量克制。

主要差距不在"缺功能"，而在**一致性和收敛度**：同一件事常常存在两到三种官方做法（服务访问有 3 种惯用法、事件广播有 2 条通道）、kernel 概念上反向引用模块（服务 ID 常量）、存档缺迁移与原子写、平台 mock 默认全量注册。这些都属于 1.0 之前应该"做减法"的范畴——每砍掉一种冗余做法，框架的学习成本和维护成本都会同步下降。

建议的主线：**先收敛 API 惯用法和事件通道，再补存档健壮性，最后做工程化（CI、版本、模板项目）**。不建议现在加新系统。

---

## 一、符合业界实践的地方（应保持）

| 实践 | 现状 | 业界对照 |
|------|------|----------|
| 单一 autoload | 插件只注册 `ServiceRegistry` 一个全局单例（`addons/mkit/plugin.gd`） | Godot 官方文档明确建议避免 autoload 泛滥；多数 addon 做不到这一点 |
| 分层 + 机器强制 | `make layering` 禁止 kernel 引用 module 类；`module.cfg` 清单 + `make module-deps` 校验引用==声明、无环、输出拓扑序 | 等价于包管理器的 manifest + 依赖图校验，开源游戏框架中罕见，是本项目最突出的优点 |
| 组合根模式 | `GameBootstrap` 只注册 kernel 服务，`ModuleBootstrap` 继承并追加模块服务，自定义服务走 override `_build_services()` | 标准 Composition Root；启动五步（注册→加载→校验→读档→进场景）清晰可背 |
| 类型化门面 | `Mkit.combat()` 等静态访问器返回具体类型 | 消除字符串 ID + cast 的样板，对 GDScript 补全和静态检查友好 |
| Definition / Runtime / Component / Service 四分 | 全部系统统一这个形状（`docs/architecture.md:133`） | 与 Unity ScriptableObject、Unreal DataAsset 的数据驱动惯例一致；`GameEffect` + `Condition` + `EffectResult` 链与 GAS 的 GameplayEffect 思路同构 |
| 事件目录 | 业务事件的类型常量与构造器集中在 `CombatEvents` / `QuestEvents` 等模块目录类 | 是对 stringly-typed 事件总线的标准缓解手段 |
| 测试与文档门禁 | unit（kernel/modules 分目录）+ integration + `demo-test` 冒烟 + `docs-check` 链接/覆盖校验 | 测试金字塔形状正确；docs-check 把文档当代码管，超出常规水准 |
| 存档信封校验 | `schema_version` 校验、legacy 字段拒绝、scope provider 支持无场景树恢复 | 方向正确（但见 P1-4 的缺口） |

---

## 二、主要发现与建议做法

### P1-1　kernel 反向认识模块：服务 ID 常量全部住在 ServiceRegistry

**问题**：`addons/mkit/kernel/services/service_registry.gd:3-25` 定义了全部 23 个服务 ID 常量，其中 `SERVICE_COMBAT`、`SERVICE_QUEST`、`SERVICE_SHOP`、`SERVICE_DIALOGUE`、`SERVICE_WORLD`、`SERVICE_LOOT`、`SERVICE_PROGRESSION`、`SERVICE_UI` 都是模块服务。字符串常量不会触发 `make layering`（它只查类引用），但概念上 kernel 已经知道每一个模块的存在——新增一个模块要回头改 kernel 文件，这正是分层想避免的事。

**业界对照**：分层架构里下层不应枚举上层的标识符；插件式架构（如 OSGi、Unreal 模块系统）的惯例是"模块自报家门"。

**建议做法**：服务 ID 常量下放到各自的服务类，kernel 只保留 kernel 服务常量：

```gdscript
# addons/mkit/modules/combat/combat_service.gd
class_name CombatService
const SERVICE_ID := "combat"
```

`Mkit.combat()`、`ModuleBootstrap`、`module.cfg` 的 `services` 字段统一引用 `CombatService.SERVICE_ID`。顺手可以让 `make module-deps` 校验 cfg 里声明的 service id 与类常量一致。这样新增/删除模块完全不碰 kernel。

---

### P1-2　同一事实有两条广播通道，且模块自己也混用

**问题**：每个模块服务的状态变更同时走两条路——typed signal 和 DomainEvent。`QuestService`（`addons/mkit/modules/quest/quest_service.gd`）每个状态变更都要写两遍发布代码（`quest_accepted.emit(...)` + `QuestEvents.quest_accepted(...)`，全文 5 处成对出现）。订阅侧同样有两套 API：`EventService` 既有 firehose 信号 `domain_event_emitted`，又有按类型的 `subscribe()`；`QuestService._connect_events()` 两个都用了。更隐蔽的是：`_on_entity_died` 合成的 `ENEMY_KILLED` 事件直接调自己的 `notify_event`，**不进总线**——其他订阅者永远看不到这个事件，但它在 `QuestEvents` 目录里看起来是个公开事件类型。

**影响**：用户每接一个系统都要先回答"我该订 signal 还是订 event？"；维护者每加一个状态变更都要双写；合成事件的不对称行为是未来 bug 的温床。

**业界对照**：事件驱动架构的通行规则是"一个事实一条 canonical 通道"。Godot 生态里 typed signal 适合**本地点对点绑定**（UI 直连一个 service 实例），domain event 适合**跨系统解耦**——两者可以共存，但要有明确的分工规则，而不是处处双发。

**建议做法**（按成本递增任选其一）：

1. **定规则 + 文档化**（最便宜）：domain event 是 canonical 通道，模块对外只保证 event；typed signal 仅保留在"UI 高频直连"确有收益的少数地方，并在 `docs/concepts.md` 写明"订什么用什么"。
2. **自动桥接**：服务里只发 event，需要 signal 的地方由一个 10 行的桥接基类订阅 event 后转发 signal，消除双写。
3. 无论选哪个：把 `_on_entity_died` 合成的事件改为 `events.emit_domain_event(...)` 走总线（或干脆让 objective 直接匹配 `CombatEvents.ENTITY_DIED`，删掉合成层）；`domain_event_emitted` firehose 信号标注为"仅供 DebugOverlay / 录制工具"。

---

### P1-3　服务访问有三种官方惯用法，应收敛为一种

**问题**：当前并存：

- `Mkit.events()`（文档钦定的门面）；
- `EventService.find()` / `ContentService.find_resource()` 静态便捷查找（模块内部 10+ 个文件在用）；
- `ServiceRegistry.get_port()`（kernel 用）+ 已废弃但仍在的 `get_service()` + 互为别名的 `get_port_ids()` / `get_registered_service_ids()`。

同一份模块代码里 `Mkit.events()` 和 `ContentService.find_resource()` 混用（如 `quest_service.gd:19` vs `:164`）。新用户读源码学惯用法时会得到三个答案。

**业界对照**："There should be one obvious way to do it"。废弃 API 和别名在 0.1.0、还没有外部用户的阶段没有保留价值——semver 0.x 正是删它们的唯一窗口。

**建议做法**：

1. 删除 `get_service()`（deprecated）和 `get_port_ids()` 别名；0.1.0 没有兼容包袱。
2. 二选一：要么删掉各服务的 `find()` / `find_resource()` 静态方法，模块内部统一 `Mkit.xxx()`（mkit.gd 在 modules 层，模块引用它不违反分层）；要么反过来让 `Mkit.xxx()` 实现为 `XxxService.find()` 的转发。推荐前者——一个入口，文档只教一种。
3. 顺手统一词汇：对用户文档只说 "service"，"port" 这个六边形架构术语只在 kernel 内部注释出现（或干脆改名），降低概念税。

---

### P1-4　存档：无迁移路径、非原子写入、profile 写死

**问题**（`addons/mkit/kernel/save/save_service.gd`）：

1. `_validate_save_envelope` 对 `schema_version != 2` 一律拒绝（`:250-253`）——schema 一升级，老玩家存档直接变砖，没有迁移钩子。
2. `save_game` 直接 `FileAccess.open(save_path, WRITE)` 覆盖写（`:55-59`）——写到一半断电/崩溃会同时失去新旧两份存档。
3. `profile_id` 硬编码 `"profile_001"`（`:50`），多存档位无从谈起。

**业界对照**：原子写（写临时文件再 rename）是所有持久化系统的底线实践；存档迁移链（v1→v2→v3 逐级升级）是商业游戏标配（Minecraft 的 DataFixer、各家 RPG 的 save migration 都是这个思路）。

**建议做法**：

```gdscript
# 原子写
var tmp_path := save_path + ".tmp"
var file := FileAccess.open(tmp_path, FileAccess.WRITE)
file.store_string(JSON.stringify(data, "  "))
file.close()
DirAccess.rename_absolute(tmp_path, save_path)
```

迁移钩子：`_validate_save_envelope` 改为 `while found < CURRENT: data = _migrate(data, found); found += 1`，`_migrate` 默认 push_error 拒绝，子类可 override；当前的"legacy 字段拒绝"逻辑就归入 v1→v2 迁移器的拒绝分支。`profile_id` 提为 `@export`。这三项都不破坏现有 API。

---

### P1-5　平台 mock 服务默认全量注册，违背"按需付费"

**问题**：`GameBootstrap._build_services()`（`game_bootstrap.gd:50-53`）无条件注册 `AnalyticsServiceMock` / `AdServiceMock` / `IAPServiceMock` / `CloudSaveServiceMock`。一个单机 jam 游戏跑起来，"Services online" 列表里有 ads 和 iap——既放大了新用户对框架体积的感知（22 个服务），也意味着永远有四个用不到的对象常驻。

**业界对照**：框架默认面应该是最小可用集，可选能力 opt-in（pay for what you use）。Godot 社区对 addon 的常见抱怨正是"装一个插件带来一堆我不要的全局对象"。

**建议做法**：给 `GameBootstrap` 加 `@export var enable_platform_mocks: bool = false`（或导出一个平台服务数组），默认不注册四个 mock；demo 的 bootstrap 显式打开。`Mkit.ads()` 等访问器在未注册时返回 null 的行为已经存在，不需要新机制。同步更新 getting_started 的预期输出列表。

---

### P2-6　依赖获取靠隐式静态查找，削弱可测试性

**问题**：服务之间的依赖全部在方法体内部临时静态查找：`QuestService` 里 `Mkit.events()` 出现 6 次、`Mkit.effects()` 1 次；`GameAction._fire_effects` 内部直接摸 `ServiceRegistry`（`game_action.gd`）；`ActionService._process` **每帧**做一次 `get_port(SERVICE_TIME)` 字典查找。依赖不出现在任何签名里，单测一个 QuestService 必须先把全局 ServiceRegistry 喂好。

**业界对照**：Service Locator 在 Godot（autoload 文化）里是务实选择，不必推翻；但通行的折中是**组合根注入 + 局部缓存**——既然 `ModuleBootstrap` 已经是组合根，让它在注册完成后把依赖交给各服务，比每个方法去全局问一遍更符合"依赖显式化"的实践。

**建议做法**：

1. 给服务加一个轻量 wire 阶段：`GameBootstrap._register_kernel_services()` 末尾遍历服务，`if service.has_method("_on_services_ready"): service._on_services_ready()`；服务在这里把 `_events := Mkit.events()` 缓存为成员。方法体内的静态查找只留给 game 层代码。
2. 至少先做最小修复：`ActionService` 把 TimeService 缓存成成员，避免每帧字典查找。
3. 单测收益：测试可以直接给 `quest._events` 赋 stub，不再需要完整 bootstrap。

---

### P2-7　"模块可裁剪"的承诺与 facade/Bootstrap 的硬引用冲突

**问题**：`docs/architecture.md:53` 说"裁剪模块时按清单反向排除依赖方即可"，但 `Mkit`（mkit.gd）静态引用了全部模块服务类型，`ModuleBootstrap` 硬编码 `new()` 全部 7 个服务。真删掉 `shop/` 目录，`Mkit.shop() -> ShopService` 直接解析失败，整个门面（以及引用它的所有模块）跟着挂。文档也承认 manifest 驱动装配"尚未落地"——但用户读到"按清单排除即可"会以为现在就能做。

**建议做法**（二选一，都比现状好）：

1. **诚实文档**（零成本）：在 architecture.md 写明"当前裁剪模块需要同步删改 `mkit.gd` 对应访问器与 `ModuleBootstrap` 对应行"，把"按清单裁剪"明确标为路线图。
2. **落地 manifest 装配**（中成本）：每个模块加一个入口脚本（如 `combat/module.gd` 提供 `static func register(services: Dictionary)`），`ModuleBootstrap` 按 `module.cfg` 拓扑序 `load()` 入口脚本注册；`Mkit` 的模块访问器改为 duck-typed 或代码生成。做之前先确认有真实的裁剪需求，否则方案 1 足够。

---

### P2-8　裸字符串状态与死字段

**问题**：

- `QuestState.status` 用裸字符串 `"active"` / `"completed"` / `"turned_in"` / `"available"`，`quest_service.gd` 里逐字比较 8 处——一个拼写错误就是静默逻辑 bug，编译器帮不上忙。
- `GameCommand.priority`（`game_command.gd:8`）声明后全仓库无任何读取，是死表面；`consumed` 也只有 `command_receiver.gd` 内部两处写、无人读。

**业界对照**：状态值用枚举/常量是 GDScript 静态类型化的基本功；YAGNI——0.x 阶段每个无人使用的公开字段都是未来的兼容负债。

**建议做法**：

```gdscript
# quest_state.gd
const STATUS_AVAILABLE := "available"
const STATUS_ACTIVE := "active"
const STATUS_COMPLETED := "completed"
const STATUS_TURNED_IN := "turned_in"
```

（存档兼容要求保留字符串值，所以用 String 常量而非 enum。）删除 `GameCommand.priority`；`consumed` 要么在 `CommandService.dispatch` 里真正消费它（已 consumed 的命令不再路由），要么一并删除。

---

### P2-9　ContentService 类型键用文件名而非 class_name

**问题**：`get_all_by_type("ability_definition")` 的类型键是"脚本文件名去扩展名"，不是 `class_name`（`docs/concepts.md:288` 专门加了警告框）。需要一个警告框来解释的 API 就是 footgun：用户改个文件名，运行时查询静默变空。

**建议做法**：类型键改用 `script.get_global_name()`（即 `class_name`，如 `"AbilityDefinition"`），无 class_name 时回退文件名。过渡期两个键都注册以保持兼容，docs 警告框随之删除。`AudioDefinition.TYPE_NAME` 这类常量同步更新。

---

### P3-10　工程化缺口：无 CI、无 CHANGELOG、目标 Godot 钉在 dev 版

**问题**：

- 仓库没有 `.github/workflows`——`make ut / int / layering / module-deps / docs-check` 这套优秀的门禁目前完全依赖本地自觉。
- `plugin.cfg` version 0.1.0，无 CHANGELOG，docs 也没有版本/兼容性承诺页。
- `docs/getting_started.md:9` 前置条件是 "Godot 4.7-dev"——要求用户装开发版是真实的采用门槛，且 dev 版行为漂移会让 bug report 无法归因。

**建议做法**：

1. 加一个 GitHub Actions workflow：下载对应版本 Godot headless（社区有现成 action，如 `chickensoft-games/setup-godot`），跑 `make ut int docs-check`。Makefile 已经把入口收敛好了，CI 只是搬运。
2. 钉到最近的 Godot stable 并写进 `plugin.cfg` 描述与 docs；若确实依赖 4.7 的新 API，在 README 写明是哪个。
3. 加 `CHANGELOG.md`（Keep a Changelog 格式），从下一个改动开始记；P1-3 的删 API 动作正好是第一条目。

---

### P3-11　DX 细节：验证步骤冗余、学习材料是 2945 行 god script

**问题**：

1. `docs/getting_started.md` 第 4 步让用户往任意脚本临时塞 `print(ServiceRegistry.get_port_ids())`——但 `GameBootstrap` 本来就会打印 `[mkit] GameBootstrap runtime services: ...`（`game_bootstrap.gd:31`）。让用户写临时代码去复制框架已有的输出，是不必要的摩擦。
2. "从 demo 复制哪些文件开始改"的表格把用户引向 `game/village_rpg_demo.gd`——一个 2945 行、200 个函数的根脚本。作为 showcase 它合格，作为"复制起点"它是反面教材：用户复制后第一件事就是面对一个 god object。
3. 文档处处教 `if combat == null: push_error(...); return` 的取服务判空仪式——但 bootstrap 之后内置服务实际上保证存在，这套仪式让用户代码膨胀且暗示框架不可靠。

**建议做法**：

1. 第 4 步改为"运行后在 Output 面板找 `[mkit] GameBootstrap runtime services:` 这一行"，删掉临时代码步骤——5 分钟上手变 3 分钟。
2. 业界惯例是 "minimal starter + kitchen-sink demo" 双轨：新增 `game_template/`，内容只有 bootstrap 场景 + 一个能移动攻击的玩家 + 一个敌人 + 一条任务，总代码量控制在 300 行内；demo 保持现状作为完整 showcase，"复制起点"表格改指模板。
3. 文档分两类示例：内置服务直接 `Mkit.combat().resolve(req)` 不判空（bootstrap 保证）；只有"可选/自注册服务"（ui、关闭的平台 mock）示范判空。补一句规则："`ModuleBootstrap` 启动成功后，服务表内服务保证非空。"

---

## 三、建议优先级

| 序 | 动作 | 成本 | 收益 |
|----|------|------|------|
| 1 | P1-3：删 deprecated/别名 API，统一服务访问为 `Mkit.xxx()` 一种惯用法 | 低 | 学习成本与源码示范性立即改善；0.x 是唯一窗口 |
| 2 | P1-2：定事件通道规则，消除双写，合成事件入总线 | 中 | 每个新模块/新用户都受益 |
| 3 | P1-4：存档原子写 + 迁移钩子 | 低 | 数据安全底线，纯增量改动 |
| 4 | P1-1：服务 ID 常量下放模块 | 低 | 分层语义自洽，新模块不再碰 kernel |
| 5 | P1-5：平台 mock 改 opt-in | 低 | 默认面缩小 4 个服务 |
| 6 | P2-8 / P2-9：状态常量、删死字段、类型键改 class_name | 低 | 消 footgun |
| 7 | P3-10：GitHub Actions + 钉 stable + CHANGELOG | 低 | 门禁从自觉变强制 |
| 8 | P2-6：组合根 wire 阶段 + 服务依赖缓存 | 中 | 可测试性、每帧查找消除 |
| 9 | P3-11：getting_started 简化 + minimal starter 模板 | 中 | 第一小时体验 |
| 10 | P2-7：模块裁剪——先改文档，manifest 装配按需求再做 | 低/高 | 承诺与现实一致 |

## 四、不建议现在做

- **不建议引入完整 DI 容器**。Godot 的 autoload + 组合根已经够用，P2-6 的轻量 wire 即可拿到可测试性收益；上容器是过度设计。
- **不建议为了"业界惯例"把 Dictionary payload 全面类型化**。事件目录 + 构造器已经是 stringly-typed 总线的标准缓解；最多在事件目录里补 payload key 常量，不要造一堆 payload 类。
- **不建议现在做 manifest 驱动的运行时装配**（P2-7 方案 2），除非出现真实的裁剪用户。7 行的 `ModuleBootstrap` 是目前最易读的真相来源。
- **不建议加新模块**。当前 12 个模块 + 23 个服务的表面已经到了"先收敛再扩张"的临界点。

---

## 五、P2 / P3 处理记录（2026-06-11）

- P2-6：`GameBootstrap` 增加服务注册后的 `_on_services_ready()` wire 阶段；`ActionService` 缓存 `TimeService` / `EffectService`，`GameAction` 使用注入的 effect service；`QuestService` 缓存 content/events/effects 依赖。
- P2-7：文档改为区分"运行时不注册某服务"与"物理删除模块目录"，并明确 `Mkit` / `ModuleBootstrap` 仍硬引用内置模块，manifest 自动装配是路线图。
- P2-8：`QuestState` 增加 `STATUS_*` 字符串常量，addon 内任务状态比较改用常量；删除未使用的 `GameCommand.priority`；`CommandService.dispatch()` 拒绝已 consumed 命令。
- P2-9：`ContentService.get_all_by_type()` 优先注册 `class_name` 类型键，同时保留旧文件名键作为兼容别名；文档和测试改用 `AbilityDefinition` / `ItemDefinition`。
- P3-10：新增 `.github/workflows/ci.yml`、`CHANGELOG.md`、`docs/compatibility.md`；项目目标版本、plugin 描述和文档从 Godot 4.7-dev 收敛到 Godot 4.6.3 stable。
- P3-11：`getting_started.md` 删除临时代码验证路径，改指 `GameBootstrap runtime services` 输出；新增 `game_template/` 最小 starter，demo 保留为完整 showcase，不再作为根脚本复制起点。
