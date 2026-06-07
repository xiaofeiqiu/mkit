
## 七、如果允许大改：更清晰易懂的目标架构

如果可以破坏兼容、迁移现有 demo 内容、重写一部分测试，建议把 mkit 从“很多全局服务 + 固定节点路径约定”重塑为“模块声明 + 实体契约 + typed runtime port”的结构。目标不是增加层数，而是让每个系统的入口、依赖、数据流一眼可见。

### 1. 用 `MkitModule` 明确每个模块的边界
- 现状：`GameBootstrap` 一次性注册所有服务，模块是否需要某服务只能从源码里找。
- 大改建议：每个模块提供一个 `MkitModule` 定义，声明：
  - `module_id`
  - `provided_services`
  - `required_services`
  - `content_types`
  - `save_scopes`
  - `event_types`
- 结果：`combat`、`inventory`、`quest`、`world` 变成可读的功能包，而不是只靠目录命名理解。

示例目标结构：

```text
addons/mkit/modules/combat/
  combat_module.gd
  services/
  components/
  definitions/
  effects/
  events/
```

### 2. 把 `ServiceRegistry` 从字符串服务定位器改成 typed runtime context
- 现状：任何代码都能 `ServiceRegistry.get_service("xxx")`，依赖是隐式的。
- 大改建议：保留唯一 autoload，但它只持有 `MkitRuntimeContext`；模块初始化时拿到 typed ports。
- 结果：模块依赖在初始化阶段固定，运行中不再到处查全局字符串。

目标风格：

```gdscript
var combat := runtime.get_port(CombatPort) as CombatPort
var events := runtime.get_port(EventPort) as EventPort
```

### 3. 用实体契约替代硬编码节点路径
- 现状：大量代码依赖 `Components/HealthComponent`、`Controllers/AbilityController`。
- 大改建议：实体根节点实现 `EntityContract`，组件注册到实体自身的 component map。
- 结果：场景树仍可保留 `Components/` 和 `Controllers/`，但它们只是默认布局，不再是模块之间的强耦合。

目标边界：

```text
EntityRoot
  owns identity
  owns component registry
  exposes get_component(type_or_id)
```

`HealthComponent`、`StatsComponent`、`InventoryController` 不再需要知道彼此的路径，只依赖实体契约。

### 4. 把 `EventService` 拆成事件目录 + 事件总线
- 现状：`EventService` 同时包含强类型信号、DomainEvent 构造、recent event 记录。
- 大改建议：
  - `EventBus` 只负责发布/订阅
  - `EventCatalog` 声明所有事件类型和 payload schema
  - 各模块自己的事件放在模块目录内
- 结果：任务、UI、日志、分析都订阅统一事件，但事件定义不再堆在一个类里。

### 5. 把战斗拆成三段：意图、结算、应用
- 现状：`HitboxComponent`、`DealDamageEffect`、`HealthComponent` 都参与伤害链路，理解成本偏高。
- 大改建议：
  - `DamageIntent`：谁想造成什么伤害
  - `DamageResolution`：规则结算结果，纯数据
  - `DamageApplication`：把结果应用到目标实体并发事件
- 结果：碰撞、技能、陷阱、环境伤害都只产生 `DamageIntent`，后续流程一致。

### 6. 统一“可变数值”的基础模型
- 现状：`StatsComponent`、`HealthComponent`、`ResourcePoolComponent`、`ProgressionState.currency` 都有各自数值语义。
- 大改建议：抽出三类明确模型：
  - `StatSet`：可被 modifier 改变的属性集合（攻击、防御、最大生命）
  - `ResourceSet`：当前值/最大值资源池（生命、法力、耐力）
  - `Wallet`：离散货币与账号级数值
- 结果：生命不再特殊到和 mana 完全割裂，货币也不会混进战斗资源池。

### 7. 让 Definition / Instance / Component / Service 的关系更机械
- 现状：大多数模块遵循这个形状，但不同模块仍有细节差异。
- 大改建议：每个模块都按固定目录和固定职责实现：
  - `Definition`：静态配置，只做 content id 和 validation
  - `Runtime` / `Instance`：运行时状态，纯数据或 RefCounted
  - `Component`：挂在实体上，拥有实体局部状态
  - `Service`：跨实体流程，不保存具体实体私有状态
- 结果：新增模块时不需要重新发明组织方式。

### 8. Save 从“遍历节点”改成“注册 save scope”
- 现状：`SaveService` 遍历 `Saveable`，`SaveableComponent` 依赖外部代理收集。
- 大改建议：
  - 每个模块声明自己的 `save_scope`
  - 实体注册自己的 component save keys
  - SaveService 只协调 schema/version/migration
- 结果：存档结构从“场景树扫描结果”变成“模块声明的持久化契约”，迁移更可控。

### 9. Bootstrap 改成模块装配器
- 现状：`GameBootstrap._build_kernel_services()` 手写注册全部内置服务。
- 大改建议：`GameBootstrap` 只做三件事：
  - 读取启用的 `MkitModule`
  - 检查依赖与 service 冲突
  - 按拓扑顺序初始化模块
- 结果：关闭 shop/quest/world 这种模块不再需要改源码或忍受无用服务常驻。

### 10. 大改后的推荐分层

```text
Game Content
  scenes, .tres content, custom states, presentation

Mkit Modules
  combat, inventory, quest, dialogue, world, shop
  each module declares services, events, content types, save scopes

Kernel Runtime
  runtime context, module loader, action/effect/command/event bus, save coordinator

Platform Adapters
  analytics, iap, ads, cloud save, audio backend
```

## 八、大改版验收标准
- [ ] 每个模块有一个入口声明文件，能看出它提供什么、依赖什么
- [ ] 运行时代码不再散落硬编码 service id 字符串
- [ ] 模块间通过 typed port / event / effect 通信，而不是互相找具体节点路径
- [ ] 实体组件查找走实体契约，不直接依赖 `Components/` 或 `Controllers/`
- [ ] 存档 schema 能从模块声明推导，不依赖隐式场景树扫描
- [ ] 新增一个模块时，有固定模板：definition、runtime、component、service、events、effects、tests、docs
