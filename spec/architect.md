# mkit 架构优化建议（可统一/应拆分/保持边界）

## 目标
把现有实现改成“边界更清晰、职责更单一、可持续扩展”的状态，同时尽量最小改动兼容现有内容。

## 一、先决判断
### 不建议大改的原则
- 不改 `addons/mkit` 的内容组织（保留游戏内容在 `game/`）
- 不引入新层级（保持 Kernel / Module / Game）
- 优先在 `addons/mkit` 内通过小模块抽象收口重复代码

## 二、优先级建议（高→低）

### P1（先做，收益高、改动可控）
1. 把“按服务 ID 获取”做统一常量化
- 问题：大量硬编码字符串（`"combat"`、`"events"`、`"content"`）
- 建议：统一使用 `ServiceRegistry.SERVICE_*` 常量；`BuiltinCommands` 常量也优先复用
- 影响：低；主要是可维护性/拼写错误风险降低

2. 抽取 `EntityComponentAccessor`（实体访问层）
- 问题：多个模块重复 `get_node_or_null("Components/..")`、`get_node_or_null("Controllers/..")`
- 建议：新增 `addons/mkit/modules/entity/entity_accessor.gd`（或扩展 `EntityRoot`）
  - `get_component(component_name: String)`
  - `get_controller(controller_name: String)`
  - `get_node_for_entity(part: String, name: String)`
- 影响：中；一刀切替换现有节点查找可减少耦合

3. 统一服务取值安全姿势
- 问题：`has_service` 后再 `get_service`、`get_node` 分散
- 建议：在关键路径封装 `ServiceLookup`（可选）或统一使用 `get_typed`，统一失败提示
- 影响：低

### P2（中等优先）
4. 抽象“通用可恢复数值资源”基类
- 问题：`HealthComponent` 与 `ResourcePoolComponent` 有明显重复（当前值/上限/变更信号/更新边界）
- 建议：
  - 增 `addons/mkit/modules/combat/resource/attribute_resource_component.gd` 这类抽象基类
  - `HealthComponent` 继承此基类并保留 `dead/die/damaged` 语义
  - `ResourcePoolComponent` 复用通用增减/约束逻辑
- 边界：保持两个组件独立对外 API
- 影响：中高（涉及 save 数据字段与信号兼容，需保持兼容）

5. 重构货币效果：`AddCurrencyEffect` + `SpendCurrencyEffect` 统一为增量效果
- 问题：两套类重复服务查找和错误处理
- 建议：保留两个类 API，但内部复用公共 `CurrencyDeltaEffect`
- 影响：低

6. 抽离“战斗伤害/状态传播”层级
- 问题：`CombatService.resolve` 当前兼顾计算+规则+副作用触发路径较重
- 建议：
  - `DamageCalculator` 负责数值运算
  - `CombatService` 负责解析请求、调用计算、决定击中状态
  - 事件/状态应用仍在现有组件（`HealthComponent`、`StatusEffectController`）里消费 `DamageResult`
- 影响：中

### P3（后续）
7. 细化世界/跑图职责边界
- `RunDirector` 做 run 生命周期与 room 进度；
- `RoomController` 管 room 内敌人/清理；
- `RoomLoader` 负责场景装配
- `RewardCoordinator` 只做奖励提交
- 现状可运行，但建议补上明确交互契约与注释，避免重复状态写入

8. 统一 `EventService` 事件总线粒度
- 问题：部分系统直接发 DomainEvent、部分发强类型信号
- 建议：保留强类型信号用于高频本地订阅；确保 domain 事件 payload 命名规范统一
- 影响：低

## 三、明确“应保持独立”的组件（不建议合并）
1. `AbilityController` 与 `StatsComponent`
- 前者是行为/时序/冷却控制，后者是属性模型

2. `AbilityController` 与 `CombatService`
- 前者是实体能力动作控制，后者是伤害规则服务

3. `QuestService` 与 `LootService` 与 `ShopService`
- 目标域不同：任务状态推进、掉落决策、交易执行，不应混到同一服务

4. `HealthComponent` 与 `ResourcePoolComponent` 不完全合并
- 前者有死亡生命线语义，后者是通用资源池

## 四、风险与边界约束（避免踩坑）
1. `SaveableComponent` 序列化名必须兼容
- 统一基类时不能改变现有序列化 key（`current_hp`、`dead`、`current_values`）

2. `NodePath` 约束不应被抽离破坏
- `Entity` 节点约定（`Components/`、`Controllers/`）仍应保留为默认约定

3. 任何新抽象必须兼容现有测试与游戏内容
- 尤其 `CombatService`、`AbilityController`、`SaveService`、`ContentService`

## 五、建议落地顺序（v1 改造节奏）
1. 先做 P1 的服务常量 + 查找访问层
2. 再做货币效果公共化（不改现有对外接口）
3. 再做 P2 的资源基类抽象（保留外部序列化兼容）
4. 最后做 P2 的战斗计算分层

## 六、验收标准（实现后观察）
- [ ] 关键服务调用统一用常量/`get_typed`
- [ ] 实体内部组件查找从“裸字符串路径”收敛到访问层
- [ ] 复合资源行为（生命/其他池）逻辑重复明显下降
- [ ] P2 后，`CombatService` 更易测，`HealthComponent` 仍保留死亡事件语义
- [ ] 文档中的边界说明（Kernel/Modules）与运行时行为一致

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
