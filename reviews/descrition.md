# Generated Method Description Implementation Plan

## 背景

当前 `docs/generated/html/` 来自 Godot doctool XML，XML 又来自 `addons/mkit/**/*.gd` 里的 `##` doc comment。生成器只是把 XML 的 `<description>` 渲染成表格，所以 method description 没意义的问题，主要源头不是 HTML 模板，而是源码注释本身仍有大量机械模板。

典型问题：

- `AbilityController.cast()` 现在显示为“执行 `cast` 对应的公开操作，并保持 `AbilityController` 的领域契约一致。”用户看不到它会检查 context、cooldown、cost、conditions，会先扣 cost，再走 instant effect 或 cast-time action，也看不到失败时会发 `ability_failed`。
- `SaveService.save_game()` 现在显示为“保存当前运行时状态”，但没有说明它会写 `roots`、`entities`、`scopes`，会检查重复 id，会用临时文件替换目标存档，成功/失败会发什么 signal。
- `Mkit.combat()`、`Mkit.quest()` 这类 accessor 被写成“执行 `combat` 对应的公开操作”，没有说明它们是 typed facade，返回 `ServiceRegistry` 中已注册的服务，缺失时可能得到 `null`。
- 生成页还会显示 `_ready()`、`_process()` 和私有 `_xxx()` 方法，很多行是 `No description`。这些不是用户主要 API，应隐藏、降级或明确标为 internal/hook，而不是混在 public method 表里。

## 目标

让 generated API reference 成为用户能读懂的 API 契约，而不是声明清单。

每个用户可见 method description 至少回答这些问题中的关键项：

1. 什么时候调用它，调用方是谁。
2. 它读取或修改哪类运行时状态。
3. 返回值如何解释，失败时返回什么。
4. 会发哪些 signal、写哪些 event、调用哪些 service 或触发哪些 side effect。
5. 输入参数里哪些字段必须有效，哪些字段会被写回。
6. 它在 mkit pipeline 中处在哪一步。

## 非目标

- 不手改 `docs/generated/html/` 或 `docs/generated/xml/`。
- 不重新引入旧的手写 `docs/ref` 作为第二套 API source of truth。
- 不在 `addons/mkit/` 注释里写具体 game 内容、boss、item、quest 或 demo-only 规则。
- 不把所有私有 helper 都包装成用户 API；用户文档只暴露真正需要调用或覆写的契约。

## Implementation Plan

### Phase 1: 定义用户可见 API 范围

先调整 `tools/generate_api_html.py` 的 method 分类，而不是让 Godot XML 里的所有方法都直接进用户表格：

- Public methods：非 `_` 开头、用户或 game/module 代码应该调用的方法，进入 `Methods`。
- Extension hooks：虽然以 `_` 开头但属于公开覆写契约的方法，例如 `_apply_impl()`、`_evaluate_impl()`、`_on_start()`、`_on_update()`、`_on_cancel()`、`_on_complete()`，进入 `Hooks` 或在 description 中明确“子类覆写”。
- Lifecycle methods：`_ready()`、`_process()`、`_physics_process()` 等默认不显示，除非源码提供了用户必须知道的说明。
- Internal helpers：其他 `_xxx()` 默认隐藏，避免 generated docs 出现大量 `No description`。

这一步要同步更新 docs checker，确保 public table 里不再出现用户不需要的 `No description`。

### Phase 2: 建立 description 质量标准

扩展 `tools/check_gd_doc_comments.py`，把以下机械模板列为失败：

- `并保持 .* 的领域契约一致`
- `执行 .* 对应的公开操作`
- `返回 .* 对应的数据或对象`
- `判断 .* 当前是否成立`
- `设置 .* 对应的数据或对象`
- `公开常量 .* 作为 .* 对外暴露`
- 只复述方法名、字段名、参数名，但没有行为、返回值或 side effect 的短句

新增一个 generated HTML/XML 级别的检查，防止源码漏网后仍生成到用户页：

- public method description 不能是 `No description`。
- public method description 不能包含上述模板短语。
- hidden/internal methods 不参与 public API description gate。

### Phase 3: 按风险顺序重写源码 `##` 注释

不要按文件名机械扫一遍。按用户阅读路径和 runtime 入口优先：

1. Facade 和服务入口：`Mkit`、`ServiceRegistry`、`GameBootstrap`、`ModuleBootstrap`。
2. 核心 pipeline：`CommandReceiver`、`CommandService`、`StateMachine`、`State`、`ActionService`、`GameAction`、`EffectService`、`GameEffect`、`GameplayContext`、`ActionContext`。
3. 存档契约：`SaveService`、`Saveable`、`SaveableComponent`、`EntitySaveAgent`，重点写清 `roots/entities/scopes`、重复 id、scope provider、load failure。
4. 实体访问契约：`EntityRoot`、`EntityIdentity`、`EntityContract`、`EntitySpawner`。
5. Combat / ability / health：`AbilityController`、`AbilityInstance`、`CombatService`、`HealthComponent`、`ResourcePoolComponent`、`HitboxComponent`、`HurtboxComponent`、status effect 相关类。
6. 业务模块服务：quest、dialogue、shop、loot、progression、world、ui、audio、pool、random、time。
7. Definition / Result / State 数据类：重点说明字段如何被 service 使用，方法如何构造 runtime object 或 content id。
8. Event constants 和 event factory：说明 payload shape、订阅方和何时发出。

每个 method description 用实际代码写，而不是从名字推断。重写时至少阅读：

- 该方法本体。
- 它调用的 service/component。
- 相关 signal/event。
- 相关 unit/integration test。
- cookbook 或 pipeline 文档中对同一行为的用户解释。

### Phase 4: 写法模板

方法说明保持中文，代码、id、路径、字段名保持英文。

推荐格式：

```text
## 从 ContentService 读取 AbilityDefinition，创建 AbilityInstance 并挂到 `abilities`；
## ability id 为空、definition 缺失时返回 false，重复注册视为成功并保持原实例。
func register_ability(ability_id: String) -> bool:
```

```text
## 尝试施放已注册 ability：先验证 context、cooldown、cost 和 conditions；
## 成功后扣除资源并发 `ability_cast_started`，instant ability 立即执行 effect，cast-time ability 交给 ActionService。
## 失败时发 `ability_failed` 并返回 false。
func cast(ability_id: String, context: GameplayContext) -> bool:
```

```text
## 收集 root 下的 Saveable、EntitySaveAgent 和已注册 scope provider，
## 写出 schema_version、roots、entities、scopes 到 `save_path`；重复 root/entity id 或文件替换失败时发 `save_failed`。
func save_game(root: Node) -> bool:
```

```text
## 返回 ServiceRegistry 中注册的 CombatService，用于统一伤害计算入口；
## 如果 bootstrap 尚未注册 `combat`，返回 null，调用方需要自行处理缺失服务。
static func combat() -> CombatService:
```

### Phase 5: 生成与验证

修完源码注释和生成器后运行：

```bash
python3 tools/check_gd_doc_comments.py
make docs-api
python3 tools/check_generated_docs_fresh.py --xml-dir docs/generated/xml --html-dir docs/generated/html
python3 tools/check_docs_sync.py
make docs-check
git diff --check
```

如果只改注释和 docs generator，不改 runtime 行为，可以不跑 GUT；如果重写过程中发现注释暴露了实现 bug 或 API 行为变更，再补 focused GUT，并按变更范围跑 `make ut-kernel`、`make ut-modules` 或 `make int`。

## Acceptance Criteria

- `rg "领域契约一致|对应的公开操作|对应的数据或对象|当前是否成立|公开常量" addons/mkit docs/generated/html docs/generated/xml` 不再命中用户可见 API description。
- Generated HTML 的 public `Methods` 表没有 `No description`。
- 生命周期和 internal helper 不再污染用户主 API 表；公开 hook 有清晰说明。
- `make docs-check` 通过，且 generated API 与源码注释保持同步。
- 重要入口页抽查通过：`Mkit`、`SaveService`、`AbilityController`、`CommandService`、`StateMachine`、`CombatService`、`QuestService`、`WorldService`。

## Progress Tracker

- [x] 确认 generated API 的 method 展示规则：public、hook、lifecycle、internal。
- [x] 更新 `tools/generate_api_html.py`，隐藏或分组 internal/lifecycle methods。
- [x] 扩展 `tools/check_gd_doc_comments.py`，拒绝机械模板 description。
- [x] 增加 generated HTML/XML description gate，防止 public method 输出空描述或模板描述。
- [x] 重写 facade、bootstrap、registry、core pipeline 的 method comments。
- [x] 重写 save/entity/command/action/effect/state machine 的 method comments。
- [x] 重写 combat、ability、health、status effect 的 method comments。
- [x] 重写 quest、dialogue、shop、loot、progression、world、ui、audio、pool、random、time 的 method comments。
- [x] 重写 definition/result/state/event 类的关键 method comments。
- [x] 运行 `make docs-api` 和 `make docs-check`，确认 generated docs 同步。
- [x] 抽查 generated HTML，确认用户能从 description 看懂调用时机、返回值和 side effect。
