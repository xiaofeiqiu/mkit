# mkit 大改版实施计划（基于大改版目标架构）

## 目标
在不引入新顶层范式的前提下，将 mkit 的当前实现从“服务调用分散、路径耦合强、模块职责不透明”重构为“模块声明驱动、实体契约清晰、运行时接口 typed 化”的架构。该计划以渐进式大改为目标，允许暂时破坏兼容，后续按模块完成迁移。

## 约束与前提
- 继续保留 `addons/mkit/` 与 `game/` 的职责边界。
- 仍以 `Kernel / Module / Game` 三层作为主骨架。
- 可接受短期兼容中断，但必须给出可执行的迁移路径。
- 不新增未声明的外部运行时依赖。

## 交付里程碑（四阶段）

### 阶段 0：架构基线与接口收口（1 周）
1. 在 `addons/mkit/kernel` 内补齐重构总线设计约束文档。
2. 明确 `ServiceID`、`BuiltinCommands`、事件 type 的统一枚举/常量来源。
3. 定义 `MkitModule` 约定草案（最小字段）：
   - `module_id: String`
   - `provided_services: Array[String]`
   - `required_services: Array[String]`
   - `content_types: Array[String]`
   - `save_scopes: Array[String]`
   - `register(runtime: MkitRuntimeContext): void`
4. 将当前实现中的服务清单与依赖关系输出为一页模块关系表（便于后续冻结接口）。

验收
- 能够用一页清单说明每个现有服务和模块的输入/输出依赖。
- 新建 `MkitModule` 的调用方式不影响现有运行（仅定义，不接入实际执行）。

### 阶段 1：Runtime 重构（核心基础设施）（2 周）
1. 实现 `MkitRuntimeContext` 与 typed port 访问层（`get_port(PortClass)`）。
2. `ServiceRegistry` 逐步收口：
   - 保留 autoload 入口职责。
   - 模块初始化阶段填充 typed ports，而非运行时散落字符串查询。
3. `GameBootstrap` 重构为模块装配器：
   - 读取启用模块列表。
   - 检查依赖有向图是否完整。
   - 按拓扑顺序调用模块初始化。
4. 逐步引入 `service constant + typed access` 作为兼容桥：
   - 先在新代码路径采用 typed port。
   - 旧代码保留 `ServiceRegistry` string 兼容直到完成迁移。

验收
- 可启动场景时输出模块初始化顺序和依赖树。
- `combat`、`events`、`save` 运行路径可通过 typed port 或兼容层稳定访问。

### 阶段 2：实体契约化改造（2 周）
1. 引入实体契约层（`EntityContract`）：
   - `get_component(type_or_id)` 与 `get_controller(type_or_id)`。
   - 可选 `find_node_in_contract(scope, name)` 过渡。
2. 统一替换关键模块中的硬编码路径查询：
   - `HealthComponent`、`AbilityController`、`StatsComponent`、`InventoryController`、`StatusEffectController`、`CombatService`、`ShopService`、`QuestService`、`RoomController` 等核心路径。
3. 约定组件登记行为，避免“假设路径存在”的隐式依赖。

验收
- 核心 gameplay 路径不再直接引用 `Components/...` / `Controllers/...` 字符串。
- 新建/已有实体场景能在缺省节点布局下运行。

### 阶段 3：核心域拆分（3 周）
#### 3.1 战斗域重构
1. 拆出 `DamageIntent -> DamageResolution -> DamageApplication` 三段。
2. `CombatService` 只保留请求编排与规则调用，不直接耦合状态应用细节。
3. `HealthComponent` 与 `StatusEffectController` 只消费统一 `DamageResult`。

#### 3.2 事件总线重构
1. 将 `EventService` 按“事件总线 + 事件目录 + 具体事件载荷”分层。
2. 统一事件命名和 payload schema。
3. 保留高频监听的强类型信号层，但与 domain event 方向对齐。

#### 3.3 数值模型重分层
1. 引入 `StatSet`（属性集合）、`ResourceSet`（实体资源池）、`Wallet`（货币）三类模型。
2. `HealthComponent` 在 `ResourceSet` 之上增加生命生命周期语义（死亡/复活/受击事件）。
3. `ResourcePoolComponent` 转为 `ResourceSet` 风格实现。

验收
- 战斗链路从“命中来源到效果落地”可独立单测每一段。
- 事件订阅方可按模块事件类型订阅，无需读取模块私有实现。

### 阶段 4：保存与世界流程统一（2 周）
1. 引入模块化 `save_scope` 声明：
   - 由模块声明可持久化条目和归属。
2. `SaveService` 改为按 scope 协调，不再依赖场景树隐式扫描。
3. 世界流程重构：
   - `RunDirector` 仅保留 run 状态机与流程控制。
   - `RoomLoader/RoomController/RewardCoordinator` 按职责拆明边界与接口。
4. 增加迁移脚本/脚本化导出 checklist（旧存档向新 schema 的转换策略）。

验收
- 存档读写以 scope 为主线，可在无场景树扫描条件下恢复关键状态。
- 跑图流程与奖励分发边界测试可稳定运行（至少一次完整 run）。

## 阶段优先级与依赖
1. 优先执行：阶段 1 -> 阶段 2 -> 阶段 3.1 -> 阶段 3.3 -> 阶段 3.2 -> 阶段 4  
2. 不应并行执行阶段 2 与 4，因为实体契约改动会影响 world 与 save 路径映射。  
3. 每个阶段内先完成“接口定义 + 迁移脚本 + 最小回归验证”，再进入下一阶段。

## 风险与回退策略
1. 风险：大规模路径查找替换导致空引用。  
   - 对策：保留 contract 适配层（向后兼容 `get_node` 查找）作为过渡 N 个月。
2. 风险：模块声明未覆盖边界导致初始化顺序问题。  
   - 对策：在 bootstrap 加入依赖循环检测与错误码日志。
3. 风险：存档 schema 改动导致线上数据不可读。  
   - 对策：保留版本号+迁移器链，先并行读旧 schema 再写新 schema。
4. 回退：按阶段边界保留独立分支文件夹与兼容层，回退到“上一个阶段提交”即可。

## 验收清单（最终）
- [ ] `Module -> Service -> Event -> Save` 都有声明化契约。
- [ ] 核心流程可按接口文档解释，不依赖具体场景树路径。
- [ ] `combat`、`inventory`、`quest`、`world` 的边界和生命周期可独立验证。
- [ ] 事件命名与 payload 不再由业务代码临时拼接。
- [ ] 新旧模式可并行存在，迁移路径可回滚且记录完整。

## 直接交付清单（代码与文档）
- `addons/mkit/kernel/runtime/` 下新增 runtime context 与模块加载接口。
- `addons/mkit/modules/entity/` 下新增实体契约。
- `addons/mkit/modules/combat/` 下重构战斗链路与数值模型。
- `addons/mkit/kernel/events/` 下事件总线/事件目录。
- `addons/mkit/kernel/save/` 下 save scope 与迁移支持。
- 文档更新：
  - [spec/architect.md](/Users/dev/workspace/gamedev/mkit/spec/architect.md)
  - 新建 [spec/implementation-plan.md](/Users/dev/workspace/gamedev/mkit/spec/implementation-plan.md)（本文件）
