# 代码审核报告（base: `main` → 当前分支 `dev`）

审核方式：基于 diff 的静态审核（未执行测试套件 / 未运行 Godot）。
审核范围：

- **World 模块（已提交）**：`addons/mkit/modules/world/` 下 `portal.gd`、`spawn_point.gd`、`world_router.gd`、`zone_definition.gd`
- **Dialogue 模块（工作区未提交）**：`addons/mkit/modules/dialogue/` 全部 + `addons/mkit/modules/ui/dialogue_ui.gd`
- **Bootstrap 改动**：`addons/mkit/kernel/bootstrap/game_bootstrap.gd`（注册 `dialogue` / `world` 服务）
- **测试**：`test/unit/modules/test_world_router.gd`、`test/unit/modules/test_dialogue_controller.gd`、`test/integration/test_world_pipeline_integration.gd`、`test/integration/test_dialogue_pipeline_integration.gd`、`test/integration/test_runtime_bootstrap_integration.gd`
- 文档/计划：`docs/*`、`spec/rpg-impl-plan.md`（仅文档，未做正确性审核）

整体评价：模块设计与既有 `Definition → Instance → Controller → System` 和命令/事件管线一致，防御式编程到位（大量 `null` 检查与 `is_active` 守卫），测试覆盖良好。下面是发现的问题，按严重度排序。

---

## 发现（按严重度排序）

### 1. 【正确性 / 高】`WorldRouter._get_audio()` 的 `"ui"` 回退分支恒为 `null`，且默认 bootstrap 从不注册 `"audio"` 服务 —— 区域 BGM 在真实运行中永远不会播放

`addons/mkit/modules/world/world_router.gd`（`_get_audio()`，文件末尾）：

```gdscript
func _get_audio() -> AudioManager:
	if ServiceRegistry.has_service("audio"):
		return ServiceRegistry.get_service("audio") as AudioManager
	if ServiceRegistry.has_service("ui"):
		return ServiceRegistry.get_service("ui") as AudioManager   # <- 恒为 null
	return null
```

- `"ui"` 服务由 `UIManager`（`extends Node`）注册（见 `ui_manager.gd:13`），而 `AudioManager` 也是 `extends Node`，二者是**兄弟类**而非父子。因此 `get_service("ui") as AudioManager` **永远返回 `null`**，这是一段死分支。
- 更关键的是：`game_bootstrap.gd._register_kernel_services()` 注册了 events/content/.../quest/shop/dialogue/world，但**从未注册 `"audio"`**。整个仓库中只有测试文件 (`test_world_router.gd:145`、`test_world_pipeline_integration.gd:81`) 手动注册了 `"audio"`。
- **后果**：`ZoneDefinition.bgm_id` 配置的区域背景音乐在默认 bootstrap 下静默失效；单测之所以通过，是因为它们手动塞了 `AudioProbe` 进 `"audio"`，从未走到也无法走通 `"ui"` 回退分支（该分支无测试覆盖）。
- **建议**：删除 `"ui"` 回退分支（它在语义和类型上都不可能成立）；若希望框架默认支持 BGM，应在 bootstrap 注册一个 `AudioManager` 为 `"audio"`，或在文档中明确「BGM 需游戏侧注册 `audio` 服务」。

---

### 2. 【正确性 / 中】`DialogueController.start()` 在对话因起始节点无效而立即结束时仍返回 `true`，误导调用方

`addons/mkit/modules/dialogue/dialogue_controller.gd`（`start()` 第 20–34 行，`_enter_node()` 第 102–121 行）：

```gdscript
func start(dialogue_id, context) -> bool:
	...
	dialogue_started.emit(dialogue_id)         # 已发出 started
	...
	_enter_node(definition.start_node_id)      # 若 start_node_id 无效 -> 内部调用 end()
	return true                                # 仍然返回 true
```

`_enter_node()` 在 `definition.get_node(node_id) == null` 时调用 `end()`（置 `runtime = null` 并发 `dialogue_ended`）。此时 `start()` 仍返回 `true`。

- **触发场景**：`DialogueDefinition.start_node_id` 配置错误（指向不存在的 node）。
- **后果**：调用方 `DialogueInteractable._interact_impl()`（`dialogue_interactable.gd:15`）以 `if not dialogue.start(...): return false` 判断成功，会继续 `emit_npc_talked(npc_id)`，但实际上对话已经「started→ended」瞬间结束、`is_active()` 为 `false`。即一次配置错误被当成交互成功，并触发了 `npc_talked`（可能误推进任务目标）。
- **建议**：`start()` 末尾改为 `return is_active()`（或在 `_enter_node` 失败路径上让 `start` 返回 `false`），使「立即结束」被识别为失败。

---

### 3. 【正确性 / 中（plausible）】`WorldRouter` 的延迟 `_finalize_zone_entry` 依赖新场景已就绪，使用真实 `SceneRouter` 时存在时序脆弱性

`addons/mkit/modules/world/world_router.gd`（`_on_scene_changed` → `_finalize_zone_entry.call_deferred()`）：

- 真实 `SceneRouter.change_scene()`（`scene_router.gd:19`）调用 `get_tree().change_scene_to_file()`，Godot 会把实际场景切换**延迟**到帧末空闲；随后**同步**发出 `scene_changed`。`_on_scene_changed` 再 `call_deferred(_finalize_zone_entry)`。
- finalize 内 `place_player_at_spawn()` 依赖**新场景里的 `SpawnPoint` 已加入树并执行过 `_ready`**（`spawn_point.gd` 在 `_ready` 才 `add_to_group`）。两段都在延迟队列上，FIFO 顺序下场景切换通常先执行，但这依赖 Godot 内部延迟调用次序，属于已知 footgun。
- 单测/集成测试用的是**同步**的 `TestSceneRouter`（立即 `add_child` 后同步发信号），因此无法暴露真实引擎下的时序问题。
- **建议**：在 `_finalize_zone_entry` 找不到 spawn / player 时增加重试（如再 `call_deferred` 一帧）或显式等待 `tree_changed`；至少补一个使用真实 `SceneRouter` 的集成用例以验证生产路径。

---

### 4. 【正确性 / 低】`_finalize_zone_entry` 忽略 `place_player_at_spawn()` 的返回值 —— 放置失败时仍标记进区 + 播放 BGM

`addons/mkit/modules/world/world_router.gd`（`_finalize_zone_entry`）：

```gdscript
place_player_at_spawn(spawn_id)      # 返回值被丢弃
current_zone_id = to_zone_id
zone_changed.emit(from_zone_id, to_zone_id)
... 播放 BGM
```

- **触发场景**：目标 spawn id 不存在、或场景中没有 `player` 组节点。
- **后果**：玩家停留在旧坐标（或未被移动），但 `zone_changed` / `zone_entered` 已照常发出、BGM 照常播放，调用方无从得知放置失败，玩家可能卡在错误位置。
- **建议**：放置失败时至少 `push_warning`，或发出可观测的失败信号，便于内容侧排查 spawn 配置。

---

### 5. 【正确性 / 低（edge）】运行时替换 `"scenes"` 服务会泄漏旧 `SceneRouter` 的 `scene_changed` 连接

`addons/mkit/modules/world/world_router.gd`（`_resolve_services`）：

```gdscript
if scene_router == null and ServiceRegistry.has_service("scenes"):
	scene_router = ServiceRegistry.get_service("scenes") as SceneRouter
if scene_router != null and not scene_router.scene_changed.is_connected(_on_scene_changed):
	scene_router.scene_changed.connect(_on_scene_changed)
```

- 仅当 `scene_router == null` 时才重新解析。`test_world_pipeline_integration.gd` 正是靠 `world.scene_router = null` 触发重解析来切换到 `TestSceneRouter`，但**旧 `SceneRouter` 上对 `_on_scene_changed` 的连接从未断开**。
- **后果**：若生产中真的热替换 `"scenes"` 服务（或测试里旧 router 仍会发信号），`_finalize_zone_entry` 可能被重复触发。当前测试因旧 router 不再发信号而侥幸通过。
- **建议**：重解析前先断开旧连接，或在 `scene_router` 引用变化时统一管理连接生命周期。

---

### 6. 【整洁度 / 低】`SpawnPoint` 硬编码组名与 `WorldRouter.spawn_group` 可配置导出不一致（虚假灵活性）

- `WorldRouter` 暴露 `@export var spawn_group := "spawn_point"` 和 `@export var player_group := "player"`，但 `spawn_point.gd:7` 硬编码 `add_to_group("spawn_point")`。
- **后果**：一旦使用者修改 `WorldRouter.spawn_group`，`_find_spawn_point` 将查不到任何 `SpawnPoint`，且无报错——导出项给了「可配置」的错觉却会静默失效。`player_group` 同理（玩家入组由外部完成，导出项同样误导）。
- **建议**：要么让 `SpawnPoint` 读取/响应同一配置（如从 `WorldRouter` 读组名），要么移除导出项、统一用常量，二选一保持一致。

---

### 7. 【整洁度 / 低】`go_to_zone` 缺少并发/重入保护，`_pending_*` 可被覆盖

同一帧内两次 `go_to_zone`，第二次会覆盖 `_pending_zone_id/_pending_spawn_id`；两次 `scene_changed` 触发两次 finalize，第二次因 `_pending_zone_id == ""` 提前返回，可能导致最终 `current_zone_id` 与预期不符。属边界场景。

- **建议**：若不支持快速连续切区，可在 `_pending_zone_id != ""` 期间拒绝新的 `go_to_zone`。

---

## 测试覆盖评估

- World：`go_to_zone` 成功/默认 spawn 回退/失败回滚、spawn 放置、`zone_changed`+`zone_entered`+BGM、未知/空 zone 优雅失败均有覆盖；集成测试串起 portal→换场→放置→任务推进→发奖，覆盖到位。
- Dialogue：start/条件过滤/choose 推进/线性 advance 到结束/重复 start 拒绝，单测覆盖完整；集成测试覆盖「交互→选择接任务→对话结束→再交互推进并结算奖励」。
- **覆盖缺口**：
  - `_get_audio()` 的 `"ui"` 回退分支（见 #1）——无测试，且实际不可达；
  - 使用**真实 `SceneRouter`** 的换场时序（见 #3）——当前仅同步 stub；
  - `DialogueDefinition.start_node_id` 配错导致「start 即 end」的路径（见 #2）；
  - bootstrap 注册的 `world`/`dialogue` 与真实 `"scenes"` 协同的端到端路径。

## 结论

无导致编译失败或崩溃的硬伤；所引用的类/方法签名（`EventRouter.emit_*`、`ConditionEvaluator.evaluate_all`、`EffectExecutor.execute_many`、`DomainEvent.create`、`SceneRouter` 信号）均与现有代码一致。

**优先处理**：#1（BGM 在生产环境静默失效 + 死分支）与 #2（`start()` 误报成功）。其余为健壮性 / 整洁度改进。

> 说明：本报告未执行 `make ut`。建议在合并前实际跑一遍 World / Dialogue 单测与集成测试确认。
