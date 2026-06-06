# mkit 全面代码审核

## 进度追踪

| 编号 | 问题 | 优先级 | 状态 |
|------|------|--------|------|
| B1 | EffectExecutor/RandomService/TimeService 生命周期不一致 | P1 | ✅ 已完成 |
| B2 | CombatResolver 静态单例绕过 ServiceRegistry | P1 | ✅ 已完成 |
| B3 | AbilityController 越界访问 _recharge_duration | P2 | ✅ 已完成 |
| B4 | HealthComponent 鸭子类型 has_method | P2 | ✅ 已完成 |
| B5 | get_typed_resource 静默返回错误类型 | P0 | ✅ 已完成 |
| R1 | ActionRunner 每帧重查 TimeService | P3 | ☐ |
| R2 | EventRouter damage_applied 无类型参数 | P2 | ✅ 已完成 |
| R3 | StatsComponent 核心集合无类型标注 | P2 | ✅ 已完成 |
| R4 | RunDirector 内联实例化工具类（明确约定即可） | P3 | ✅ 已完成 |
| R5 | `_initialize_runtime_systems` 空方法 | P4 | ✅ 已完成 |
| S1 | ContentRegistry _extract_content_id OCP 违反 | P1 | ✅ 已完成 |
| S2 | RunDirector 职责过多 | P3 | ✅ 已完成 |
| S3 | ProgressionSystem 继承链不一致 | P3 | ✅ 已完成 |
| S4 | HIGHEST_ONLY/LOWEST_ONLY 枚举有名无实 | P0 | ✅ 已完成 |

---



**范围：** `addons/mkit/` 全量 addon 代码（kernel + modules）  
**版本：** main 分支（2026-06-06）  
**关注点：** 功能边界清晰度 · 代码简洁性 · SOLID 原则合规性

---

## 一、总体评价

mkit 整体架构设计健全——服务注册表、事件驱动管道、HFSM、Resource/Instance/Node 三层数据模型等核心思路正确，addon 边界得到了严格保护（没有把具体游戏内容写入 addon）。代码风格统一，注释策略一致。

主要缺陷集中在以下三类：

| 类别 | 问题数量 | 典型症状 |
|------|----------|----------|
| 边界模糊 | 5 处 | 静态单例绕过 ServiceRegistry、跨类访问私有字段、效果执行器生命周期缺失 |
| 类型安全 | 6 处 | 无类型 `Dictionary`/`Array`、untyped 信号参数、鸭子类型 `has_method` |
| SOLID 违反 | 4 处 | OCP 违反（content ID 提取硬编码）、SRP 违反（RunDirector 职责过重）、空实现（`pass` 方法）等 |

**评分（0–10）：**

| 维度 | 分数 | 说明 |
|------|------|------|
| 架构设计 | 8.5 | 管道、分层、数据模型设计优秀；singleton 不一致性扣分 |
| 功能边界 | 7.5 | kernel/module 分层清晰；部分模块内耦合过强 |
| 类型安全 | 5.5 | 大量核心集合类型未标注，破坏强类型承诺 |
| 代码简洁性 | 8.0 | 方法短小，命名清晰；少数文件（RunDirector）偏长 |
| SOLID 合规 | 6.5 | OCP 和 SRP 有明确违反；其余原则基本遵循 |

---

## 二、功能边界问题

### B1 — EffectExecutor 生命周期游离于服务树之外

**文件：** `kernel/effects/effect_executor.gd`  
**严重性：** 高

```gdscript
class_name EffectExecutor
extends RefCounted  # ← 注册为服务，但不是 Node
```

`game_bootstrap.gd` 中，`EventRouter`、`ActionRunner`、`CommandRouter` 等服务都通过 `add_child` 挂入 ServiceRegistry 节点树，拥有完整生命周期。但 `EffectExecutor` 仅通过 `register_service` 注册，没有进入节点树，`recent_results` 缓冲不会被 scene 切换回收。

同样问题存在于 `RandomService` 和 `TimeService`（也是 RefCounted，未挂树）。

**建议：** 将三者改为 `extends Node` 并在 bootstrap 中用 `add_child` 注册，与其他服务保持一致。若有意保持 RefCounted（轻量级），需在 CLAUDE.md 中说明"非生命周期服务"模式，并确保 `recent_results` 在适当时机清空。

---

### B2 — CombatResolver 静态单例绕过 ServiceRegistry

**文件：** `modules/combat/combat_resolver.gd`  
**严重性：** 高

```gdscript
class_name CombatResolver
extends RefCounted
static var _default: CombatResolver = null

static func get_default() -> CombatResolver:
    if _default == null:
        _default = CombatResolver.new()
    return _default
```

所有其他系统通过 `ServiceRegistry.get_service("effects")` 等获取服务实例，但 `CombatResolver` 提供了独立的静态单例接口。这导致：

1. 测试时无法 mock 或替换 `CombatResolver`
2. 用法不一致——调用方需要知道这个例外存在

**建议：** 移除 `_default` 静态变量；在 `game_bootstrap.gd` 中创建并注册：`ServiceRegistry.register_service("combat", CombatResolver.new())`。调用方统一通过 ServiceRegistry 获取。

---

### B3 — AbilityController 越界访问 AbilityInstance 私有字段

**文件：** `modules/abilities/ability_controller.gd` 第 148、166 行  
**严重性：** 中

```gdscript
# to_save_data()
if instance._recharge_duration > 0.0:
    recharge_durations[key] = instance._recharge_duration

# from_save_data()
instance._recharge_duration = _restore_recharge_duration(key, data, remaining)
```

GDScript 下划线前缀表示"约定私有"，但 `AbilityController` 直接读写 `AbilityInstance._recharge_duration`，破坏封装。

**建议：** 在 `AbilityInstance` 中新增 `get_recharge_duration() -> float` / `set_recharge_duration(v: float)` 方法，或将字段改为 public `recharge_duration`（去掉下划线），明确语义。

---

### B4 — HealthComponent 通过 has_method 鸭子类型访问 StatusEffectController

**文件：** `modules/health/health_component.gd` 第 48–50 行  
**严重性：** 中

```gdscript
var controller = owner.get_node_or_null("Controllers/StatusEffectController")
if controller == null or not controller.has_method("apply_status"):
    return
```

`controller` 是无类型 `var`，使用运行时方法检查规避静态类型。正确方式是 `as StatusEffectController` 强转，与代码库其他地方的约定一致。

**建议：**
```gdscript
var controller := owner.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
if controller == null:
    return
```

---

### B5 — ContentRegistry.get_typed_resource 类型不匹配时静默返回错误类型

**文件：** `kernel/registry/content_registry.gd` 第 37–43 行  
**严重性：** 高

```gdscript
func get_typed_resource(content_id: String, expected_script: Script) -> Resource:
    var res := get_resource(content_id)
    if res == null:
        return null
    if expected_script != null and res.get_script() != expected_script:
        pass  # ← 什么都不做！类型不匹配被静默忽略
    return res
```

`pass` 导致即使脚本类型不符，依然返回资源，调用方做 `as AbilityDefinition` 会得到 null 却不知道原因。

**建议：**
```gdscript
if expected_script != null and res.get_script() != expected_script:
    push_error("ContentRegistry: type mismatch for '%s'" % content_id)
    return null
```

---

## 三、代码简洁性与可读性问题

### R1 — ActionRunner 每帧从 ServiceRegistry 查询 TimeService

**文件：** `kernel/actions/action_runner.gd` 第 27–30 行  
**严重性：** 低

```gdscript
func _process(delta: float) -> void:
    var time: TimeService = null
    if ServiceRegistry.has_service("time"):
        time = ServiceRegistry.get_service("time") as TimeService  # 每帧两次字典查询
    var scaled_delta := time.get_scaled_delta(delta) if time != null else delta
```

每帧做两次字典哈希查找，时间服务不会动态消失，缓存一次即可。

**建议：** 在 `_ready` 中缓存 `_time_service`。

---

### R2 — EventRouter emit_damage_applied 参数无类型

**文件：** `kernel/events/event_router.gd` 第 4、32 行  
**严重性：** 中

```gdscript
signal damage_applied(result)              # ← 无类型
func emit_damage_applied(result) -> void:  # ← 无类型
```

整个代码库遵循强类型约定，此处是明显例外，且是高频调用路径。

**建议：**
```gdscript
signal damage_applied(result: DamageResult)
func emit_damage_applied(result: DamageResult) -> void:
```

---

### R3 — StatsComponent 核心集合全部无类型

**文件：** `modules/stats/stats_component.gd` 第 19–21、53、148、215 行  
**严重性：** 中

```gdscript
var modifiers_by_stat: Dictionary = {}       # 实际类型：Dictionary[String, Array[StatModifier]]
var cached_values: Dictionary = {}           # 实际类型：Dictionary[String, float]
var dirty_stats: Dictionary = {}             # 实际类型：Dictionary[String, bool]

var list: Array = modifiers_by_stat[...]     # 应为 Array[StatModifier]
var modifiers: Array = modifiers_by_stat...  # 应为 Array[StatModifier]
func _get_persistent_modifiers() -> Array:   # 应为 Array[Dictionary]
```

GDScript 2.0 支持 `Dictionary[K, V]` 和 `Array[T]` 标注，核心系统理应使用。

---

### R4 — RunDirector 内联实例化工具类，绕过依赖注入

**文件：** `modules/room/run_director.gd` 第 49、107 行  
**严重性：** 中

```gdscript
room_graph = DungeonGenerator.new().generate_linear(...)  # 第 49 行
var reward_system := RewardSystem.new()                    # 第 107 行
```

`DungeonGenerator` 和 `RewardSystem` 被视为无状态工具直接 `new()`，在单元测试中无法替换。其他系统均通过 ServiceRegistry 查找或注入依赖。

**建议：** 若 `DungeonGenerator` / `RewardSystem` 确实是无状态纯函数工具，可以接受；但需在文档中明确说明"工具类可直接实例化"与"服务通过注册表获取"的区分规则。

---

### R5 — game_bootstrap._initialize_runtime_systems 是空方法

**文件：** `kernel/bootstrap/game_bootstrap.gd` 第 122–123 行  
**严重性：** 低

```gdscript
func _initialize_runtime_systems() -> void:
    pass
```

空钩子方法增加阅读负担，读者需要确认这不是遗漏逻辑。若计划保留作为子类扩展点，应在 CLAUDE.md 中说明；否则直接删除，在 `boot()` 中移除对它的调用。

---

## 四、SOLID 原则问题

### S1 — 开放/封闭原则（OCP）违反：ContentRegistry 硬编码资源 ID 属性名

**文件：** `kernel/registry/content_registry.gd` 第 68–89 行  
**严重性：** 高

```gdscript
func _extract_content_id(res: Resource) -> String:
    for property_name in [
        "item_id", "ability_id", "status_id", "room_id", "upgrade_id",
        "entity_definition_id", "enemy_id", "loot_table_id", "reward_id",
        "stat_id", "quest_id", "dialogue_id", "shop_id", "zone_id"
    ]:
        if property_name in res:
            return str(res.get(property_name))
    return ""
```

每新增一种 Definition 类型，就需要修改 `ContentRegistry` 本身，违反 OCP。此列表目前已有 14 项，随着模块增长会继续膨胀。

**建议方案 A（接口约定）：** 要求所有 Definition 资源实现 `get_content_id() -> String`，ContentRegistry 调用该方法：
```gdscript
if res.has_method("get_content_id"):
    return res.get_content_id()
```

**建议方案 B（元数据标注）：** 使用 Godot export_category 或自定义注解，在资源上标记"这是 content_id 字段"。

---

### S2 — 单一职责原则（SRP）：RunDirector 职责过重

**文件：** `modules/room/run_director.gd`（188 行）  
**严重性：** 中

`RunDirector` 当前承担：
1. 管理 RunState（运行状态机）
2. 驱动 DungeonGenerator 生成 RoomGraph
3. 动态实例化并管理 RoomController 场景
4. 监听玩家死亡事件
5. 协调奖励选择流程
6. 向 EventRouter 发布运行事件

这是 6 个不同职责。当房间加载逻辑或奖励流程需要修改时，必须改动同一个文件。

**建议：** 将场景加载职责提取为 `RoomLoader`（或复用 `SceneRouter`），将奖励协调提取为 `RewardCoordinator`，RunDirector 只负责状态机转移和事件发布。

---

### S3 — 里氏替换原则（LSP）：ProgressionSystem 继承链不一致

**文件：** `modules/progression/progression_system.gd` 第 2 行  
**严重性：** 低

```gdscript
class_name ProgressionSystem
extends Saveable  # ← 其他所有可存档模块都 extends SaveableComponent
```

`HealthComponent`、`StatsComponent`、`AbilityController`、`StatusEffectController`、`InventoryController` 均继承 `SaveableComponent`，而 `ProgressionSystem` 继承 `Saveable`（基类）。`SaveManager` 按 `SaveableComponent` 查找子节点时行为可能不一致。

**建议：** 统一改为 `extends SaveableComponent`，或在文档中明确说明两种 Saveable 基类的适用场景。

**解决（已完成）：** 采用建议的第二方案——`ProgressionSystem` 保持 `extends Saveable`，不改基类。复核确认这两个基类是**有意分离**的两条契约：`Saveable` 是顶层全局存档单元（在 `game_bootstrap.gd` 构建、`add_child` 进 `ServiceRegistry`、带稳定 `save_id`，由 `SaveManager` 整树遍历收集），`SaveableComponent` 是实体内 `Components/` / `Controllers/` 子状态（按 `get_save_key()` 按实体聚合，避免同名跨实体覆盖）。`ProgressionSystem` 与 `QuestSystem`、`AudioManager` 同属前者，已与真正的同类一致；它**不是**实体组件。原建议的第一方案（改 `SaveableComponent`）反而会破坏存档——`SaveManager` 只遍历 `is Saveable` 的节点，全局系统改成组件后将永远不被收集。修复内容：在 `CLAUDE.md` 与 `docs/ref/Saveable.md` 明确两类基类的选择规则；并新增 `test_tc_svc_17_global_systems_use_saveable_base` 锁定「全局系统是 `Saveable` 而非 `SaveableComponent`」，同时强化 `test_tc_svc_01` 断言实体组件「是 `SaveableComponent` 而非 `Saveable`」，从两侧锁死该约定。

---

### S4 — 依赖倒置原则（DIP）：StatModifier HIGHEST_ONLY / LOWEST_ONLY 枚举有名无实

**文件：** `modules/stats/stat_modifier_definition.gd` 第 4 行  
`modules/stats/stats_component.gd` 第 179–193 行  
**严重性：** 中

```gdscript
# StatModifierDefinition
enum StackingRule { STACK, REPLACE_SAME_SOURCE, HIGHEST_ONLY, LOWEST_ONLY, UNIQUE }

# StatsComponent._apply_stacking_rule
match modifier.stacking_rule:
    StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE: ...
    StatModifierDefinition.StackingRule.UNIQUE: ...
    _:
        pass  # ← HIGHEST_ONLY 和 LOWEST_ONLY 静默退化为 STACK
```

`HIGHEST_ONLY` 和 `LOWEST_ONLY` 在枚举中声明但实现中缺失，调用方设置这两个规则后得到的是默认堆叠行为，无任何警告。这是接口承诺与实现不符的典型违反。

**建议：** 补全实现，或加断言：
```gdscript
StatModifierDefinition.StackingRule.HIGHEST_ONLY:
    # 保留已有同 modifier_id 中数值最大的一个
    for existing in list.duplicate():
        if existing.modifier_id == modifier.modifier_id and existing.value >= modifier.value:
            return  # 新的更小，不添加
        elif existing.modifier_id == modifier.modifier_id:
            list.erase(existing)  # 移除旧的，添加新的更大值
```

---

## 五、已确认优点（勿破坏）

以下是代码库中设计优秀、需要保持的部分：

| 特性 | 位置 | 评价 |
|------|------|------|
| HFSM LCA 转换 | `kernel/state_machine/state_machine.gd` | 正确计算最低公共祖先，避免冗余 exit/enter |
| GameEffect + Condition 组合 | `kernel/effects/game_effect.gd` | `apply()` 先评估 conditions 再执行，数据驱动且可测 |
| StatsComponent dirty 缓存 | `modules/stats/stats_component.gd` | 懒计算 + dirty flag，避免每帧重算 |
| CommandRouter 广播复制 | `kernel/commands/command_router.gd:53` | `broadcast()` 正确 `duplicate(true)` payload，防止多接收方共享可变数据 |
| GameBootstrap 循环检测 | `kernel/bootstrap/game_bootstrap.gd:148` | `_is_same_scene_as_self()` 防止无限 bootstrap 循环 |
| ContentRegistry 重复 ID 检测 | `kernel/registry/content_registry.gd:19` | 注册时立即报错，不延迟到使用时 |
| StatusEffectDefinition 丰富的堆叠规则 | `modules/status_effects/status_effect_definition.gd` | 6 种 StackRule 已全部在 StatusEffectController 中实现 |
| GameCommand payload 访问器 | `kernel/commands/game_command.gd` | `get_vector2/get_string/get_float` 提供类型安全的 payload 读取 |
| AbilityController 费用检查与扣费分离 | `modules/abilities/ability_controller.gd` | `_has_enough_cost` / `_pay_cost` 分开，先检查再扣费，原子性清晰 |

---

## 六、改进优先级汇总

| 优先级 | 编号 | 问题 | 工作量 |
|--------|------|------|--------|
| P0 | B5 | `get_typed_resource` 静默返回错误类型 | XS（2 行） |
| P0 | S4 | HIGHEST_ONLY/LOWEST_ONLY 枚举有名无实 | S |
| P1 | B1 | EffectExecutor/RandomService/TimeService 生命周期不一致 | S |
| P1 | B2 | CombatResolver 静态单例绕过 ServiceRegistry | S |
| P1 | S1 | ContentRegistry _extract_content_id OCP 违反 | M |
| P2 | B3 | AbilityController 越界访问 _recharge_duration | XS |
| P2 | B4 | HealthComponent 鸭子类型 has_method | XS |
| P2 | R2 | EventRouter damage_applied 无类型参数 | XS |
| P2 | R3 | StatsComponent 核心集合无类型标注 | S |
| P3 | R1 | ActionRunner 每帧重查 TimeService | XS |
| P3 | S2 | RunDirector 职责过多 | L |
| P3 | S3 | ProgressionSystem 继承链不一致 | XS |
| P3 | R4 | RunDirector 内联实例化工具类（明确约定即可） | XS |
| P4 | R5 | `_initialize_runtime_systems` 空方法 | XS |
