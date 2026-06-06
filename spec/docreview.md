# mkit docs/code 偏差审核

**范围：** `docs/` 与当前 `addons/mkit/`、`game/demo/`、`Makefile` 的一致性  
**日期：** 2026-06-06  
**产物：** 只记录审核结果，不修改 `docs/` 正文  

---

## 一、结论速览

整体结论：`docs/` 与现有代码总体同步，结构性覆盖是健康的。当前没有发现断链、错文件路径、layer 索引漏类或把未实现 class 写成已实现 ref 页的严重问题。

自动检查结果：

| 检查项 | 结果 |
|--------|------|
| `addons/mkit` 当前 `class_name` 数 | 132 |
| `docs/ref/*.md` 数 | 133 |
| 缺失 ref 页 | 0 |
| 额外 ref 页 | `ServiceRegistry`，合理：它是 autoload 脚本，无 `class_name` |
| `docs/ref` 的 `## 文件` 路径 | 0 处错误 |
| Markdown 本地链接 | 0 处断链 |
| `kernel_layer.md` / `module_layer.md` / `platform_adapter_layer.md` 类索引 | 与当前源码路径一致 |
| 公共方法签名漂移 | 无实质参数漂移，只有源码多行签名和文档单行签名的空白差异 |

主要问题集中在两类：

1. 少数 ref 页漏列当前公开 API。
2. 个别描述仍是旧实现或生成模板式表述，影响维护者按文档操作。

---

## 二、需要同步的真实偏差

### D1 — `AbilityController.unregister_ability()` 未写入 ref 页

**严重性：** 中  
**文件：** `docs/ref/AbilityController.md`

源码存在公开方法：

- `addons/mkit/modules/abilities/ability_controller.gd:47`：`func unregister_ability(ability_id: String) -> void`

但 ref 页接口块只列出 `register_ability()`、`has_ability()`、`can_cast()`、`cast()`、冷却查询、存档方法等，缺少 `unregister_ability()`：

- `docs/ref/AbilityController.md:36-45`

**影响：** 奖励回滚、临时技能移除、测试清理或 debug 操作若需要注销 ability，读文档的人会以为没有正式入口。

**建议：**

- 在接口块补 `func unregister_ability(ability_id: String) -> void`。
- 在函数使用场景说明它只从 `abilities` 字典移除实例，不主动发 `ability_registered` 的反向信号，也不处理正在执行的 cast action。

### D2 — `CommandReceiver.configure_receiver_id()` 未写入 ref 页

**严重性：** 中  
**文件：** `docs/ref/CommandReceiver.md`

源码存在公开方法：

- `addons/mkit/kernel/commands/command_receiver.gd:31`：`func configure_receiver_id(id: String) -> void`

但 ref 页接口块只列出：

- `receive_command(command)`
- `handle_unhandled_command(command)`

见 `docs/ref/CommandReceiver.md:35-36`。

**影响：** `EntitySpawner` 或运行时测试若在 `_ready()` 前后配置 receiver id，文档没有告诉维护者这个显式配置入口存在。

**建议：**

- 在接口块补 `func configure_receiver_id(id: String) -> void`。
- 在函数使用场景中说明它忽略空字符串，只负责设置 `receiver_id`，不会自动重新注册到 `CommandRouter`。

### D3 — `ProgressionSystem.spend_currency()` 未写入 ref 页

**严重性：** 中  
**文件：** `docs/ref/ProgressionSystem.md`

源码存在公开方法：

- `addons/mkit/modules/progression/progression_system.gd:27`：`func spend_currency(currency_id: String, amount: int) -> bool`

它会校验空 id / 非正数、委托 `ProgressionState.spend_currency()`，成功后发 `currency_changed`：

- `addons/mkit/modules/progression/progression_system.gd:28-35`

ref 页接口块缺少该方法：

- `docs/ref/ProgressionSystem.md:30-36`

**影响：** Shop、IAP、meta progression UI 等需要扣长期货币时，文档只暴露 `add_currency()` 和 `unlock_or_level_up()`，容易诱导调用方绕过系统直接改 `ProgressionState`。

**建议：**

- 在接口块补 `func spend_currency(currency_id: String, amount: int) -> bool`。
- 在使用场景说明其与 `unlock_or_level_up()` 的区别：前者是通用扣款入口，后者是升级购买事务。

### D4 — `GameBootstrap` 对 `initial_scene_path` 和 `_load_profile()` 的描述过旧

**严重性：** 中  
**文件：** `docs/ref/GameBootstrap.md`

当前文档说：

- `initial_scene_path` 是“资源或节点路径”：`docs/ref/GameBootstrap.md:18`
- `_load_profile()` 是“读档或创建默认 profile 的扩展点，默认为空”：`docs/ref/GameBootstrap.md:37`

源码实际行为：

- `_load_profile()` 若 `SaveManager.save_path` 存在，会调用 `save_manager.load_game(tree.root)`，不是空实现：`addons/mkit/kernel/bootstrap/game_bootstrap.gd:126-134`
- `_enter_initial_scene()` 要求 `initial_scene_path` 指向现有 `PackedScene`，且显式拒绝指向包含当前 `GameBootstrap` 的同一场景：`addons/mkit/kernel/bootstrap/game_bootstrap.gd:137-155`

**影响：** 文档会误导使用者把 `initial_scene_path` 当普通节点路径使用，或以为 bootstrap 不会自动读档。

**建议：**

- 把字段说明改为“初始场景资源路径，必须是可加载的 `PackedScene`”。
- 更新 `_load_profile()` 使用场景：当前实现会在文件存在时自动从 `SaveManager.save_path` 读入 `get_tree().root`。
- 更新 `_enter_initial_scene()`：补充同场景防无限重载保护。

### D5 — `SaveManager.save_path` 字段说明错误

**严重性：** 低  
**文件：** `docs/ref/SaveManager.md`

当前文档说：

- `save_path` 是“资源或节点路径”：`docs/ref/SaveManager.md:17`

源码实际是文件路径，默认 `user://save.json`，通过 `FileAccess.open(save_path, FileAccess.WRITE/READ)` 读写：

- `addons/mkit/kernel/save/save_manager.gd:7`
- `addons/mkit/kernel/save/save_manager.gd:22`
- `addons/mkit/kernel/save/save_manager.gd:36`

**影响：** 容易让维护者把它当 `res://` 资源或 NodePath，而不是 Godot 文件系统路径。

**建议：** 改为“存档文件路径，默认 `user://save.json`；传给 `FileAccess` 读写”。

### D6 — `SaveableComponent` 文档描述的“实体聚合器”当前未形成闭环

**严重性：** 中  
**文件：** `docs/ref/SaveableComponent.md`

文档说 `SaveableComponent` 会由“后续实体聚合器按组件 key 收集”，并把组件数据写入实体快照：

- `docs/ref/SaveableComponent.md:5`
- `docs/ref/SaveableComponent.md:27`

当前 `SaveManager` 只遍历 `Saveable`：

- `addons/mkit/kernel/save/save_manager.gd:54-60`
- `addons/mkit/kernel/save/save_manager.gd:63-68`

仓库当前未发现通用实体聚合器把 `SaveableComponent` 自动纳入 `SaveManager` payload。各组件的 `to_save_data()` / `from_save_data()` 本身是真实现，但“谁统一收集这些组件”在 docs 中写得比当前实现更完整。

**影响：** 维护者可能以为只要组件继承 `SaveableComponent` 就会被 `SaveManager.save_game()` 自动保存；实际需要宿主实体或其他系统显式聚合。

**建议：**

- 若当前阶段没有实体聚合器：在 `SaveableComponent.md` 明确“契约已实现，自动实体聚合入口尚未在 addon 中提供；调用方需由宿主 Saveable 聚合”。
- 若这是设计目标：补实现、测试和 docs，同步 `SaveManager` / save pipeline。

### D7 — `docs/pipeline.md` 的 Scene Spawn Pipeline 未反映 `use_pool` 分支

**严重性：** 低  
**文件：** `docs/pipeline.md`

管线页当前写成纯 direct-load：

- `docs/pipeline.md:165-167`：`load PackedScene and instantiate -> add to SceneTree.current_scene`

源码当前已经有可选 pool 分支：

- `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd:5`：`@export var use_pool: bool = false`
- `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd:14-17`：`use_pool` 且存在 `"pool"` 服务时取 `ObjectPool`
- `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd:34-36`：pool 存在时 `pool.acquire(scene_path, parent)`

`docs/ref/SpawnSceneEffect.md` 已经写对，只有 pipeline 总览页落后。

**建议：** 在 Scene Spawn Pipeline 中加入：

```text
if use_pool and pool service exists
  -> ObjectPool.acquire(scene_path, current_scene)
else
  -> load PackedScene and instantiate
```

---

## 三、可以改进的文档质量问题

### Q1 — ref 页字段说明有明显模板化痕迹

**严重性：** 低，但范围较广

示例：

- `docs/ref/CommandReceiver.md:22`：`max_history` 被描述为“集合字段”，但它是命令历史上限 `int`。
- `docs/ref/StateMachine.md:17`：`initial_state_path` 被描述为“资源或节点路径”，实际是 HFSM 状态路径字符串。
- `docs/ref/StateMachine.md:23`：`previous_path` 也被描述为“资源或节点路径”，实际是上一状态路径。

这类文本没有破坏接口块，但降低了 ref 页作为维护入口的可信度。

**建议：**

- 优先清理核心入口类：`GameBootstrap`、`SaveManager`、`StateMachine`、`CommandReceiver`、`StatsComponent`、`AbilityController`、`ProgressionSystem`。
- 字段说明应回答“这个字段由谁写、谁读、生命周期是什么、默认值有什么语义”，避免“代码字段。实际存在于当前实现中”这类低信息量描述。

### Q2 — 建议新增一个服务 id 对照表

**严重性：** 低

`GameBootstrap` 当前注册的服务 id 包括：

```text
events, content, random, time, actions, effects, commands, scenes, pool, save,
progression, analytics, ads, iap, cloud_save, quest, shop, audio, dialogue, world
```

证据：`addons/mkit/kernel/bootstrap/game_bootstrap.gd:65-99`。

`docs/ref/GameBootstrap.md:33` 用类名描述了创建哪些服务，但没有给出 id -> class 的表。`docs/ref/ServiceRegistry.md:48-52` 也只举了少数 id 示例。

**建议：**

- 在 `docs/ref/GameBootstrap.md` 或 `docs/kernel_layer.md` 增加“Bootstrap Service IDs”表。
- 标清 `ui` / `debug` 这类不是 bootstrap 创建、而是节点 `_ready()` 自注册的动态 service，避免和 bootstrap service 混在一起。

### Q3 — docs 可以增加可重复的同步检查入口

**严重性：** 低

本次审核用到的机械检查很适合沉淀成工具：

- `class_name` 与 `docs/ref` 覆盖关系。
- `docs/ref/<Class>.md` 的 `## 文件` 路径与源码路径一致性。
- layer 文档中 class link 与源码层级一致性。
- public `signal` / public field / public non-private method 与 `## 接口` 块的一致性。
- docs 内部链接断链检查。

**建议：**

- 增加 `tools/check_docs_sync.py`。
- 增加 `make docs-check`，作为每次改 public API 后的轻量门禁。

---

## 四、确认无问题或暂不算偏差的项

- `ServiceRegistry` 有 ref 页但没有 `class_name`：合理。它由 `plugin.gd` / `project.godot` 作为 autoload `ServiceRegistry` 暴露，docs 也已说明不要声明同名 `class_name`。
- `DialogueInteractable._interact_impl()` 与 `Portal._interact_impl()` 写在接口块：虽然是下划线 protected override，但源码确实存在，并且这是 `Interactable.interact()` 的扩展点；暂不算错误。
- `SpawnPoint._ready()` 写在 ref 页：源码确实存在，且其加入 `SpawnPoint.GROUP` 的行为是该类的关键语义；暂不算错误。
- `EntityRoot` 的 `identity` / `state_machine` / `command_receiver` 字段：是 `@onready var`，自动扫描器若只看 `var` 会漏掉，但文档与源码一致。
- `docs/readme.md`、`docs/kernel_layer.md`、`docs/module_layer.md`、`docs/platform_adapter_layer.md`、`docs/demo_testing.md` 的当前结构与仓库入口、Makefile target 基本一致。

---

## 五、建议修复顺序

1. 先修 D1-D3：补 3 个漏记公开 API，改动小但直接影响 ref 页准确性。
2. 再修 D4-D6：同步 bootstrap/save 语义，尤其是 `SaveableComponent` 自动聚合边界，避免误导实现者。
3. 再修 D7：补 pipeline 的 `use_pool` 分支。
4. 最后做 Q1-Q3：清理模板字段说明，并把本次检查固化为 `make docs-check`。

## 六、验证说明

本次是文档审核和静态对照，未运行 GUT。未运行原因：没有修改 addon 行为，也没有修改现有 docs 正文；只新增审核记录 `spec/docreview.md`。
