# Architecture

Mkit 的三层模型、依赖规则、ServiceRegistry 模式、实体约定。读完能回答"我的代码放哪层、为什么"。

---

## 层模型

```mermaid
flowchart TB
    Game["**Game Content**\nres://game/\n你的场景、关卡、角色脚本\n.tres 配置资源"]
    Modules["**Module Layer**\naddons/mkit/modules/\n战斗、任务、对话、房间、物品\nInventory、Progression、Shop…"]
    Kernel["**Kernel Layer**\naddons/mkit/kernel/\nCommand / HFSM / Action / Effect / Event\nContentService / SaveService / ServiceRegistry…"]
    Platform["**Platform Adapters**\n默认全部为 Mock\nAnalytics · IAP · Ads · CloudSave"]

    Game -->|"依赖"| Modules
    Game -->|"依赖"| Kernel
    Modules -->|"依赖"| Kernel
    Kernel -->|"依赖"| Platform

    classDef mkitCore  fill:#4A90D9,color:#fff,stroke:#2C6FAC
    classDef userOwned fill:#7ED321,color:#fff,stroke:#5A9A18
    classDef platform  fill:#6B7280,color:#fff,stroke:#4B5563

    class Modules,Kernel mkitCore
    class Game userOwned
    class Platform platform
```

🟢 绿色 = 你实现 / 🔵 蓝色 = mkit 负责

| 层 | 职责 | 路径 |
|----|------|------|
| **Game Content** | 你的游戏逻辑、场景、配置 | `res://game/` |
| **Module Layer** | 可复用的游戏系统（战斗、任务、对话…） | `addons/mkit/modules/` |
| **Kernel Layer** | 框架骨架（管线、服务注册、存档…） | `addons/mkit/kernel/` |
| **Platform Adapters** | 平台接口，开发期用 Mock | `addons/mkit/kernel/services/` |

**依赖只能向下，不能反向。** kernel 不依赖任何 module；modules 不依赖 game。

---

## ServiceRegistry 模式

`ServiceRegistry` 是整个框架唯一的 autoload。所有服务通过它注册和获取：

```gdscript
# 获取服务
var combat := ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService
if combat == null:
    push_error("CombatService not available")
    return

# 检查服务是否存在
if ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) != null:
    var save := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService

# 注册自定义服务（在 GameBootstrap 子类中 override _register_kernel_services）
ServiceRegistry.register_service("my_service", MyService.new())
```

`GameBootstrap._ready()` 在启动时自动注册所有内置服务，顺序：
1. `_register_kernel_services()` — 创建并注册所有服务
2. `_load_content()` — 将 `resource_databases` 加载进 ContentService
3. `_validate_content()` — 校验所有 ContentDefinition 的合法性
4. `_load_profile()` — 若存档文件存在则自动 load
5. `_enter_initial_scene()` — 切换到 `initial_scene_path`（deferred）

### 完整服务 ID 对照表

| 常量名 | 服务 ID | 类型 | 说明 |
|---------|----------|------|------|
| `SERVICE_EVENTS` | `"events"` | `EventService` | 领域事件广播与订阅 |
| `SERVICE_CONTENT` | `"content"` | `ContentService` | ContentDefinition 注册与按 ID 查询 |
| `SERVICE_RANDOM` | `"random"` | `RandomService` | 有种子随机数，支持复现 |
| `SERVICE_TIME` | `"time"` | `TimeService` | delta / 帧管理 |
| `SERVICE_ACTIONS` | `"actions"` | `ActionService` | GameAction 生命周期管理 |
| `SERVICE_EFFECTS` | `"effects"` | `EffectService` | GameEffect 执行链，含 trace |
| `SERVICE_COMMANDS` | `"commands"` | `CommandService` | GameCommand 路由分发 |
| `SERVICE_COMBAT` | `"combat"` | `CombatService` | 伤害结算（base → 暴击 → 防御 → final） |
| `SERVICE_SCENES` | `"scenes"` | `SceneService` | 场景切换封装 |
| `SERVICE_POOL` | `"pool"` | `PoolService` | 对象池（Node 实例复用） |
| `SERVICE_SAVE` | `"save"` | `SaveService` | 存读档，收集场景树 `Saveable` 并写 `scopes`（支持无场景树恢复） |
| `SERVICE_PROGRESSION` | `"progression"` | `ProgressionService` | 经验、升级、货币 |
| `SERVICE_QUEST` | `"quest"` | `QuestService` | 任务接受 / 推进 / 完成 |
| `SERVICE_SHOP` | `"shop"` | `ShopService` | 商店购买 |
| `SERVICE_AUDIO` | `"audio"` | `AudioService` | 音频播放 |
| `SERVICE_DIALOGUE` | `"dialogue"` | `DialogueService` | 对话树运行时 |
| `SERVICE_WORLD` | `"world"` | `WorldService` | 世界区域 / Zone 管理 |
| `SERVICE_LOOT` | `"loot"` | `LootService` | 战利品掷骰与奖励分发 |
| `SERVICE_ANALYTICS` | `"analytics"` | `AnalyticsServiceMock` | 数据统计（默认 Mock） |
| `SERVICE_ADS` | `"ads"` | `AdServiceMock` | 广告（默认 Mock） |
| `SERVICE_IAP` | `"iap"` | `IAPServiceMock` | 内购（默认 Mock） |
| `SERVICE_CLOUD_SAVE` | `"cloud_save"` | `CloudSaveServiceMock` | 云存档（默认 Mock） |
| `SERVICE_UI` | `"ui"` | `UIManager` | UIManager.open_screen 与 UI 生命周期 |

> `"random"`, `"time"`, `"effects"`, `"combat"` 这四个服务是 `RefCounted`，不在场景树中，其余为 `Node`（`ServiceRegistry` 的子节点）。

---

## Definition / Instance / Controller / System 四分模式

每个游戏系统的对象都遵循同一形状：

| 角色 | 基类 | 生命周期 | 示例 |
|------|------|----------|------|
| **Definition** | `Resource` / `ContentDefinition` | 静态，编辑器配置，保存为 `.tres` | `AbilityDefinition` |
| **Instance** | `RefCounted` | 运行时，每个实体持有一份 | `AbilityInstance` |
| **Controller / Component** | `Node` / `SaveableComponent` | 挂在实体节点树上，生命周期绑定实体 | `AbilityController`, `HealthComponent` |
| **System / Service** | `Node` / `RefCounted` | 全局单例，通过 ServiceRegistry 获取 | `CombatService`, `QuestService` |

```gdscript
# Definition — 编辑器创建，通过 ContentService 查询
var def := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
var ability_def := def.get_resource("fireball") as AbilityDefinition

# Controller — 从实体节点树查找
var ability_ctrl := owner.get_node("Controllers/AbilityController") as AbilityController

# System — ServiceRegistry 获取
var combat := ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT) as CombatService
```

---

## 实体节点约定

每个游戏实体遵循固定的节点树结构，所有 module 组件都依赖此约定的路径：

```
EntityRoot                   ← 继承 EntityRoot，持有 entity_id
  EntityIdentity             ← 唯一实体 ID（运行时生成）
  Components/                ← 数据组件
    HealthComponent
    StatsComponent
    ResourcePoolComponent
    StatusEffectController
    ExperienceComponent
    InventoryController
    AbilityController
    …
  Controllers/               ← 系统控制器（输入、AI、交互）
    StateMachine
    InteractionComponent
    …
  Presentation/              ← 渲染与动画
    AnimationPlayer          ← Action 播动画的接缝节点（固定路径）
    Sprite2D / …
```

**路径是合约**——module 组件默认通过固定布局约定访问，阶段性路径通过 `owner.get_node_or_null("Components/HealthComponent")` 等。  
新接入代码优先通过 `EntityContract` 语义入口（`get_component` / `get_controller`）获取组件与控制器，避免直接依赖绝对路径。

```gdscript
# 正确：通过 owner 按约定路径访问
var health := owner.get_node_or_null("Components/HealthComponent") as HealthComponent

# 推荐：通过 EntityContract 访问（可配置）
var health2 := owner.get_component(HealthComponent)

# 错误：硬编码绝对路径或依赖节点顺序
var health := get_node("/root/World/Player/Components/HealthComponent")  # 脆弱
```

---

## 扩展 Bootstrap

需要注册自定义服务时，继承 `GameBootstrap` 并 override `_register_kernel_services`：

```gdscript
class_name MyBootstrap
extends GameBootstrap

func _register_kernel_services() -> void:
    super._register_kernel_services()          # 先注册所有内置服务
    var my_svc := MyCustomService.new()
    ServiceRegistry.register_service("my_service", my_svc)
```

> `super()` 必须在自定义服务注册前调用，否则内置服务尚未就绪。

> 模块迁移与发布说明统一收敛到本文与 [pipeline.md](pipeline.md)，并以 `spec/implementation-plan.md` 的里程碑完成记录为准。
