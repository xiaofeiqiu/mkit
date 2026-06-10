# Mkit 设计与架构 Review：对照业界常规做法

> 评审范围：`addons/mkit/`（kernel + modules）、`docs/concepts.md`、`docs/architecture.md`、bootstrap / 事件 / 存档 / 实体契约等核心实现。
> 评审视角：Godot 4 插件生态惯例、Unreal GAS / Subsystems、Unity ScriptableObject / DI 框架、《Game Programming Patterns》等业界通行模式。

---

## 总评

mkit 的**骨架选型基本都站在业界主流做法这一边**：节点组合式实体、Resource 数据驱动、Command → State → Action → Effect → Event 管线（与 Unreal GAS 同构）、平台服务 Ports & Adapters + Mock、带 schema 版本号的存档。这些方向不需要推翻。

主要问题不在"选了什么模式"，而在**执行上违反了自己宣称的规则**和**几处与业界惯例相悖的细节**。按严重程度排序：

| # | 问题 | 严重度 | 业界常规 |
|---|------|--------|----------|
| 1 | kernel 反向依赖 modules，违反自己文档里的分层铁律 | 🔴 高 | 框架核心层零业务依赖，模块经组合根注册 |
| 2 | EventService 是"上帝事件总线"，kernel 硬编码所有业务域信号 | 🔴 高 | 通用总线 + 各模块自有事件目录 |
| 3 | 字符串 Service Locator 返回 `Object`，到处 `as` + 判空；且 `get_service` / `get_port` / `find()` 三套访问习惯并存 | 🟡 中 | 类型化静态访问器，一条 blessed path |
| 4 | 框架 addon 里内置了具体游戏 UI 和成品玩法系统 | 🟡 中 | 框架与示例内容分离（examples/ 或独立插件） |
| 5 | 模块间横向依赖隐式存在，无声明、无约束 | 🟡 中 | 显式模块依赖声明（清单/拓扑） |
| 6 | 若干实现细节：`is_class` 对脚本类无效、存档冗余写 legacy 字段、`get_all_by_type` 用文件名做 key、`GameplayContext` 弱类型字段袋 | 🟢 低 | 见各节 |

---

## 一、符合业界常规、应当保持的部分

先把做对的说清楚，避免误伤：

1. **实体 = 节点组合（EntityRoot + Components/ + Controllers/）**。这是 Godot 官方与社区公认的惯用法（"scene 即 entity，节点即 component"），比在 Godot 里硬造 ECS 更主流。`EntityContract` 提供语义入口、禁止硬编码绝对路径，方向正确。

2. **Definition（Resource）/ Runtime（RefCounted）/ Component（Node）/ Service 四分**。与 Unity 的 ScriptableObject（静态配置）+ MonoBehaviour（场景生命周期）+ 纯 C# 运行时对象的分法、Unreal 的 DataAsset / UObject / Subsystem 分法一一对应，是教科书式的数据驱动结构。

3. **Command → StateMachine → Action → Effect → Event 管线**。与 Unreal GameplayAbilitySystem 高度同构（GameAction ≈ GameplayAbility，GameEffect ≈ GameplayEffect，Condition/Tag ≈ GameplayTag 校验，GameplayContext ≈ EffectContext）。命令可序列化、可回放也是标准 Command Pattern 收益。即时与前摇技能统一为同帧 `start()+complete()`，是 GAS 里 "instant ability 也是 ability" 的同款处理。

4. **平台服务 Ports & Adapters**：`AdService` / `IAPService` / `AnalyticsService` / `CloudSaveService` 默认 Mock，替换后端只需换注册——六边形架构的标准玩法，移动游戏框架（如 Unity 的 IAP/Ads 抽象层）普遍如此。

5. **单一 autoload**（`plugin.gd` 只注册 `ServiceRegistry`，服务挂为其子节点）。Godot 插件生态的最佳实践就是尽量少占 autoload 名额，避免与宿主项目冲突。比常见的"一个框架塞八个 autoload"克制得多。

6. **存档带 `schema_version` + 迁移函数 + 显式 scope provider**；**内容注册期拒绝重复 ID + bootstrap 末尾 `validate_all()`**（fail-fast）；**RandomService 带种子可复现**；**GUT 单测 + 集成测试分层**。这些都是业界常规的"及格线以上"做法。

---

## 二、偏离业界常规的问题与建议

### 1. 🔴 kernel 反向依赖 modules（违反自己的分层铁律）

`docs/architecture.md` 明确写着："**依赖只能向下，不能反向。kernel 不依赖任何 module**"。实际代码：

| kernel 文件 | 引用的 modules 类 |
|-------------|-------------------|
| `kernel/bootstrap/game_bootstrap.gd:45-59` | `CombatService`、`ProgressionService`、`QuestService`、`ShopService`、`DialogueService`、`WorldService`、`LootService` |
| `kernel/events/event_service.gd:4` | `DamageResult`（modules/combat）；`:157` `EntityContract`（modules/entity） |
| `kernel/commands/command_receiver.gd` | `EntityContract` |
| `kernel/debug/debug_overlay.gd` | `EntityContract`、`HealthComponent` |

**业界常规**：框架核心层（Unreal 的 Engine/CoreUObject、Unity 的 package core、任何分层架构的 domain 层）对上层零引用是硬性规则，通常用编译单元/装配体物理隔离来强制（Unreal module 的 `.Build.cs` 依赖白名单、Unity asmdef）。GDScript 没有编译期隔离，所以更需要**约定 + CI 检查**来兜底。

模块的接入靠**组合根（composition root）**：核心只提供注册机制，"哪些模块参与"由最外层（game 或一个 modules 层的 bootstrap 子类）声明。这正是你们文档里已经规划但未落地的 `MkitModule` 声明文件。

**建议**：
- `GameBootstrap._build_kernel_services()` 只保留 kernel 自己的 ~13 个服务；新建 `modules/module_bootstrap.gd`（或最终的 `MkitModule` 清单机制）继承它并追加 7 个模块服务。游戏模板默认用后者，分层立刻干净。
- `EventService` 去掉对 `DamageResult` / `EntityContract` 的引用（见问题 2）。
- `debug_overlay` 要么下放到 modules，要么改为读通用接口（duck-typing / 通用 `get("health")`）。
- 加一条 CI 检查（脚本 grep kernel 引用 modules 类名即失败），把规则从文档变成机器约束——这是业界对"无法靠编译器强制的分层"的标准补救。

### 2. 🔴 EventService 是"上帝事件总线"

`event_service.gd` 在 kernel 里硬编码了 18 个业务域信号（quest、dialogue、shop、zone、run、inventory……），每个还配一个手写的 `emit_*` 方法，同一事件双轨发射（typed signal + `DomainEvent`）。

**业界常规**：全局 signal bus 本身是 Godot 社区公认的解耦手段，没问题。问题在**归属**：
- 通行做法是**总线机制归核心，事件定义归各模块**。Unreal 的 GameplayMessageSubsystem 用 channel tag + struct payload，核心不知道任何具体消息；CQRS/DDD 系统里 domain event 类型永远定义在它所属的 bounded context 内。
- kernel 里出现 `emit_quest_turned_in` 意味着：每加一个模块都要改 kernel 文件；删掉 quest 模块 kernel 也带着死代码；这正是文档里自己承认的"拆分式 EventBus / EventCatalog 尚未落地"。

**建议**：
- kernel 的 `EventService` 收敛为通用能力：`emit_domain_event(event)`、`subscribe(event_type, callable)`、recent_events 环形缓冲。
- 各模块自带一个轻量 EventCatalog（事件类型常量 + payload 构造函数，或一个模块级 signal hub 节点），quest 的事件常量住在 modules/quest 里。
- typed signal 与 DomainEvent 双轨保留其一为主：要么订阅方统一订 `domain_event_emitted` 按类型过滤（简单、但失去编辑器补全），要么模块 hub 提供 typed signal（推荐，符合 Godot 习惯），kernel 总线只做录制/调试/回放用途。

### 3. 🟡 Service Locator 的类型安全与"三套访问习惯"

现状：`get_port(String) -> Object`，调用方写 `ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService` + 判空；同时存在 `get_service()`（兼容旧路径）、`get_port()`（推荐）、`EventService.find()` / `ContentService.find_resource()`（静态便捷入口）三种习惯。

另外 `_warn_on_type_mismatch`（`service_registry.gd:95-100`）对 GDScript 脚本类**基本不工作**：`get_class()` 返回的是原生类名（如 `"Node"`），`Object.is_class()` 官方文档明确不考虑 `class_name` 声明。传 `"CombatService"` 做 expected 会得到误报警告，传原生类名又检查不到真正想要的类型。

**业界常规**：Service Locator 在游戏里是合法主流（《Game Programming Patterns》专章背书；Unreal 的 `GetSubsystem<T>()`、Unity VContainer/Zenject 的 `Resolve<T>()`），但**主流实现都是类型化的**——拿到的就是具体类型，拼写错误和类型错误在编辑器/编译期暴露，而不是运行时 warning。

**建议**：
- 在保留 registry 作底层存储的前提下，提供一层类型化静态门面，让它成为唯一推荐入口：

```gdscript
class_name Mkit
extends RefCounted

static func combat() -> CombatService:
    return ServiceRegistry.get_service(ServiceRegistry.SERVICE_COMBAT) as CombatService

static func events() -> EventService:
    return ServiceRegistry.get_service(ServiceRegistry.SERVICE_EVENTS) as EventService
# ...每个内置服务一个，返回类型写死
```

  调用方从三行样板变成 `Mkit.combat().resolve(req)`，补全、类型检查全回来了。`EventService.find()` 这类静态入口其实已经是这个方向，建议收口成一个门面而不是散在各服务上。
- `get_service` 标记 deprecated 并排期移除，文档只教一条路。
- `_warn_on_type_mismatch` 改用 `service.get_script()` 的 `get_global_name()` 比对，或干脆删掉——类型化门面落地后它没有存在价值。

### 4. 🟡 框架 addon 内置了具体游戏 UI 与成品玩法

`modules/ui/` 里有 `shop_ui.gd`、`quest_log_ui.gd`、`dialogue_ui.gd`、`reward_selection_ui.gd`、`damage_number_system.gd`。而 `concepts.md` 的核心承诺是"管线两端（输入与表现）是绿色、是你的代码"。框架自带具体 UI 与这一承诺矛盾，而且这层 UI 横向依赖了 quest/dialogue/shop/loot 几乎所有模块（见问题 5 的依赖表），是全仓库耦合最重的一块。

**业界常规**：框架/引擎插件把"能跑的完整示例"放在 `examples/`、`samples/` 或独立的 demo 插件里（Unreal 的 Lyra 是独立 sample 项目、Unity 包的 Samples~ 目录、Godot 知名插件如 Dialogic 也把 demo 场景与核心分开）。框架本体最多提供 headless 的 ViewModel/数据接口，不提供成品控件。

**建议**：把 `modules/ui/` 整体迁到 `game/`（或新建 `addons/mkit_demo/`），框架内保留的只有 UIManager 这类机制性设施。这同时消解了 ui 模块的大量横向依赖。

### 5. 🟡 模块间横向依赖隐式存在

实测各模块对其他模块类的直接引用：

```
combat    → entity (EntityContract, EntityIdentity)
inventory → entity, progression? (StatsComponent, StatModifier)
shop      → inventory, progression (InventoryController, ItemDefinition, AddCurrencyEffect…)
world     → entity, loot, interaction
loot      → inventory (ItemInstance)
dialogue  → interaction (Interactable)
ui        → quest, dialogue, shop, loot, …（最重）
ai/quest  → entity (EntityContract)
```

这些依赖**本身大多合理**（shop 依赖 inventory 天经地义），问题是它们**没有任何声明**——文档说"modules 不依赖 game"，但没说模块之间的规则；删掉 inventory 模块，shop、loot 静默编译失败。

**业界常规**：模块化框架都要求显式依赖声明并禁止环：Unreal 每个 module 的 `.Build.cs` 列 `PublicDependencyModuleNames`；Unity asmdef 列 references；Web 生态的 monorepo 用 package.json。声明的价值是工具可校验（无环、无未声明引用）+ 用户可按需裁剪。

**建议**：落地文档里已规划的 `MkitModule` 清单，每个模块一个声明（id、依赖模块列表、注册的服务、事件目录），bootstrap 按拓扑序装配。短期最低成本版本：先在每个模块目录放一个 `module.md`/`module.cfg` 声明依赖，并加 CI 脚本校验"实际引用 ⊆ 声明依赖"。`entity` 模块被 kernel 和几乎所有模块依赖，事实上已是基础设施——考虑把 `EntityContract`/`EntityRoot`/`EntityIdentity` 提升进 kernel，一并解决问题 1 的一半。

### 6. 🟢 细节问题清单

按"现状 → 业界常规 → 建议"逐条：

**(a) `ContentService.get_all_by_type` 用脚本文件名做类型 key**（`ability_definition.gd` → `"ability_definition"`，文档特意警告"不是 class_name"）。需要文档特意警告的 API 就是反惯例的 API。业界做法要么用类型本身（Unity `LoadAll<T>`、Unreal `GetAssetsByClass`），要么用显式注册的 type id。建议改用 `Script.get_global_name()`（即 class_name）做 key，或接受 `Script` 参数：`get_all_by_script(AbilityDefinition)`。

**(b) 存档每次都写 legacy 字段**。`save_service.gd:64` 把 `"payload": roots` 与 `"roots": roots` 同时写入，还有 `scope_manifest`/`save_scopes` 三处冗余索引。业界惯例是**读旧写新**（migration on read），新档只写当前 schema；旧 key 永久双写会让档案体积翻倍且后续 schema 演进越来越乱。建议：写入只留 `roots`/`entities`/`scopes` + 版本头，`_migrate_save_payload` 继续负责读旧档。另外迁移建议演进为链式（v1→v2→v3 各一个函数），这是存档系统的标准做法。

**(c) `_is_inactive_service_registry_child`（`save_service.gd:304`）是修补生命周期问题的 hack**。SaveService 需要知道"ServiceRegistry 下挂着已注销服务的尸体节点"才能正确扫描，说明 `ServiceRegistry.clear()` 注销时不清理子节点（你们的集成测试陷阱记录也踩过这个坑）。常规做法是注销即清理：`unregister_service`/`clear()` 时对 Node 型服务 `queue_free()` 或移出树，让扫描方不需要这种特判。

**(d) `GameplayContext` 是弱类型字段袋**。单一 `amount: float` + `payload: Dictionary` 自由扩展，多个 effect 串行读写同一个 ctx。GAS 的对应物（EffectContext + SetByCaller）也是类似的"上下文 blob"，所以这不算反惯例，但 GAS 用 GameplayTag 做了 key 的强约定。建议至少把 payload key 收敛为各模块导出的常量（`CombatKeys.CRIT_MULTIPLIER`），避免散落字符串；文档中"保持轻量"的警告已经到位。

**(e) `EventService` 每个事件手写 `emit_*` + 双轨发射**约 150 行纯样板。问题 2 的方案落地后自然消失，这里只记录：业界对这种样板的常规解法是事件即数据（事件类自带 `event_type` 与 payload 构造），总线只有一个 `emit`。

**(f) `EntityContract` 依赖魔法容器名** `"Components/"` / `"Controllers/"`。Godot 社区对组件发现的更常规做法是 group（`add_to_group("health_component")`）、`_ready` 时向 EntityRoot 自注册、或 `@export` 显式接线，因为节点重命名/移动不会有编译期保护。当前做法可用（文档已写清约定），但建议给 EntityRoot 加"子组件 `_ready` 自注册到字典"的路径，把节点路径查找降级为 fallback——这样组件放哪个容器、叫什么名字都不再致命。

---

## 三、优先级与落地顺序建议

1. **P0 — 分层修复**（问题 1 + 2）：模块服务表移出 kernel bootstrap；EventService 业务信号迁往模块事件目录；加 CI 分层检查。这是文档承诺与代码的最大背离，越晚修，新代码越多沿着错误依赖生长。
2. **P1 — 类型化服务门面**（问题 3）：纯增量、不破坏现有调用，立即改善所有下游代码的开发体验；顺手废弃 `get_service` 与坏掉的类型检查。
3. **P1 — UI/demo 拆出框架**（问题 4）：迁移成本低（移动文件 + 改路径），收益是框架边界一次说清。
4. **P2 — 模块清单**（问题 5）：与已规划的 `MkitModule` 合并推进，先声明后校验。
5. **P3 — 细节清单**（问题 6）：(b)(c) 建议尽早（存档格式越晚改代价越大），其余随手修。

## 参考对标

- 《Game Programming Patterns》（R. Nystrom）：Service Locator、Command、Event Queue、Component 各章
- Unreal：GameplayAbilitySystem（管线对标）、Subsystems（类型化服务获取）、Module `.Build.cs`（依赖声明）、Lyra（demo 与框架分离）
- Unity：ScriptableObject 数据驱动、asmdef 装配隔离、VContainer/Zenject（类型化 DI）
- Godot 官方文档：Saving games（组扫描存档模式）、Autoload vs regular nodes、插件最佳实践（最小 autoload 占用）
