# Doc Comment 驱动文档生成方案

日期: 2026-06-11  
范围: `addons/mkit/**/*.gd`, `docs/`, `Makefile`, CI/docs 检查链路

## 目标

把 mkit 的 API 文档来源收敛到 GDScript 源码里的 Godot doc comment：

```text
addons/mkit/**/*.gd 的 ## doc comment
  -> Godot --doctool --gdscript-docs 生成 XML
  -> HTML class reference
```

最终状态：

- `.gd` 顶层 `##` doc comment 是 API 文档唯一权威。
- legacy Markdown reference 不再手写维护；要么删除，要么变成生成产物。
- HTML 文档从 Godot 生成的 XML 派生，不再从 Markdown 手写页派生。
- `make docs-check` 能检查生成产物是否新鲜，并能发现 public API 缺 doc comment。

## 已确认的工具边界

本地 Godot CLI help 显示该 editor build 支持：

```bash
--doctool <path>
--gdscript-docs <path>
```

含义：

- `--doctool <path>`：输出 API reference XML。
- `--gdscript-docs <path>`：配合 `--doctool`，从指定路径下的 GDScript inline documentation 生成 API reference。
- CLI help 没有显示“直接输出 HTML”的开关，所以 HTML 需要第二步：接 Godot 官方 docs/Sphinx 工具链，或写一个薄的 XML -> HTML 渲染器。

## 设计原则

1. **源码为权威**  
   类、信号、字段、方法说明写在对应 `.gd` 声明附近。生成工具只读源码或 Godot XML，不读旧手写 ref 页作为长期来源。

2. **不维护双份 API 文档**  
   旧 `legacy Markdown reference.md` 只能作为一次性迁移材料。迁移完成后，不能再把它当作权威。

3. **生成链路尽量用 Godot 原生能力**  
   优先使用 `Godot --doctool --gdscript-docs` 生成 XML。repo 自定义逻辑只负责补齐 Godot 不直接提供的 HTML/检查层。

4. **注释写公共契约，不写逐行解释**  
   public class / signal / exported field / public method 必须有 doc comment；私有 helper 默认不要求。框架扩展点例外，例如 `_apply_impl()`、`_on_start()`、`_on_update()` 这类需要用户 override 的方法。

## Doc Comment 编写规范

### Class

每个 public `class_name` 前后应有 class-level `##`，说明：

- 这个类负责什么。
- 上游通常是谁调用它。
- 下游会调用哪些服务、组件或事件。
- 什么时候应该使用它。

示例：

```gdscript
## Effect 系统的抽象基类。
## 上游通常是 EffectService 或 GameAction；下游由子类落到具体 domain service/component。
## 子类 override _apply_impl() 实现实际效果，apply() 负责统一执行 conditions。
class_name GameEffect
extends Resource
```

### Public Field / Signal / Method

紧贴声明写短说明：

```gdscript
## 全局唯一的效果 id，会写入 EffectResult 并用于 trace/debug。
@export var effect_id: String = ""

## 执行前必须全部通过的条件列表；失败时 apply() 返回失败 EffectResult。
@export var conditions: Array[Condition] = []

## 执行 effect，先检查 conditions，再调用 _apply_impl()。
func apply(context: GameplayContext) -> EffectResult:
```

### Override Hook

框架要求用户覆写的方法必须写，即使方法名以下划线开头：

```gdscript
## 子类覆写的实际效果入口。默认实现返回成功但不改变世界。
func _apply_impl(context: GameplayContext) -> EffectResult:
```

## Implementation Plan

### Phase 1: 跑通 Godot XML 生成

新增 Makefile 目标：

```make
DOC_XML_DIR ?= docs/generated/xml
DOC_XML_LOG ?= /tmp/mkit_docs_xml.log

docs-xml:
	@rm -rf $(DOC_XML_DIR)
	@mkdir -p $(DOC_XML_DIR)
	$(GODOT) --headless --log-file $(DOC_XML_LOG) --path . --doctool $(DOC_XML_DIR) --gdscript-docs res://addons/mkit
```

验证点：

- Godot 能识别 `addons/mkit/**/*.gd` 的 `class_name`。
- XML 中包含 class description、method、signal、property。
- `ServiceRegistry` 这类 autoload 无 `class_name` 的脚本是否能被 doctool 收录；如果不能，优先给它补 `class_name` 的可行性评估，否则用极小 shim 处理。

执行结果（2026-06-11）：

- 已新增 `DOC_XML_DIR ?= docs/generated/xml` 和 `docs-xml` Makefile 目标。
- 试跑发现当前 headless 环境下 Godot 默认 `user://logs` 可能崩溃，因此目标额外使用 `DOC_XML_LOG ?= /tmp/mkit_docs_xml.log` 并显式传入 `--log-file`。
- `make docs-xml` 已通过，输出目录为 ignored 的 `docs/generated/xml`。
- Godot XML 已收录 addon class、method、member/property、signal、constant。
- `ServiceRegistry.xml` 已生成，说明当前 doctool 能收录该 autoload 脚本，Phase 1 不需要给 `ServiceRegistry` 增加 `class_name` 或 shim。
- `Mkit.xml` / `ModuleBootstrap.xml` 验证了已有 class-level `##` 会进入 XML 的 `brief_description` / `description`；大量 class description 仍为空，留给 Phase 2 回填。

### Phase 2: 回填源码 doc comments

迁移来源：

- 当前或旧版 legacy kernel Markdown reference
- 当前或旧版 legacy module Markdown reference
- 已验证的高层文档：`docs/architecture.md`, `docs/pipeline.md`, `docs/cookbook/*`

迁移规则：

- `## 职责` -> class-level `##`
- 字段表说明 -> 对应 `@export var` / public `var` 前的 `##`
- 方法表说明 -> 对应 public method 前的 `##`
- 信号表说明 -> 对应 signal 前的 `##`
- 不存在源码对应的旧文档不迁移，比如已删除的平台服务桩、旧 damage 中间类。

覆盖要求：

- 所有 `addons/mkit/kernel` 和 `addons/mkit/modules` 下的 `class_name`。
- 所有 public signal。
- 所有 `@export var`。
- 所有 public non-private methods。
- 常量中只强制服务 ID、内容 type name、公开枚举相关常量。

执行结果（2026-06-11）：

- 已为 `addons/mkit/kernel` 和 `addons/mkit/modules` 下 136 个 API class 回填 class-level `##` doc comment。
- 已补齐 public signal、public/non-private property、`@export var`、public method、必要常量和公开 enum 的相邻 `##` doc comment；覆盖检查结果为 `MISSING=0`。
- Override hook 覆盖了 `_apply_impl()`、`_evaluate_impl()`、`_on_start()`、`_on_update()`、`_on_cancel()`、`_on_complete()`。
- 已运行 `make docs-xml`，确认 Godot doctool 能解析新增注释并输出 XML description。
- 迁移期曾刷新旧 Markdown reference；最终链路已在 Phase 6 改为 Godot XML -> HTML，不再维护旧 Markdown reference。
- `make docs-check` 初次发现既有 docs 导航引用缺失的 `roadmap.md`；已补充 `docs/roadmap.md`，随后 `make docs-check` 通过。
- 已运行 `make layering` 和 `git diff --check`。

### Phase 3: 建立缺注释检查

新增工具，例如：

```text
tools/check_gd_doc_comments.py
```

职责：

- 扫描 `addons/mkit/kernel` 和 `addons/mkit/modules`。
- 检查 public class / signal / exported field / public method 是否有紧邻 `##`。
- 私有方法默认跳过。
- 可配置允许列表，处理 Godot lifecycle 方法 `_ready`, `_process`, `_physics_process` 等不需要对外文档的函数。
- 输出稳定、可 CI 使用的错误列表。

建议检查结果格式：

```text
doc comment coverage failed:
  addons/mkit/kernel/effects/game_effect.gd:1 class GameEffect missing class doc
  addons/mkit/kernel/effects/game_effect.gd:6 property effect_id missing doc
```

执行结果（2026-06-11）：

- 已新增 `tools/check_gd_doc_comments.py`。
- 检查范围覆盖 `addons/mkit/kernel` 和 `addons/mkit/modules`，包含 class-level doc、public signal、public/exported var、public method、公开 enum、必要常量，以及框架 override hook。
- 已对 Godot lifecycle 方法和不暴露给用户的私有 helper 做跳过处理。
- 当前运行结果为 `doc comment coverage passed.`。

### Phase 4: HTML 生成

优先级：

1. **优先接 Godot 官方 docs/Sphinx 工具链**  
   目标是复用 Godot class reference 的 XML -> HTML 生成方式，减少自维护 HTML renderer。

2. **如果官方链路过重，再写 repo-local XML -> HTML renderer**  
   这个 renderer 只读 `docs/generated/xml/*.xml`，不重新解析 `.gd`。

repo-local HTML 输出建议：

```text
docs/generated/html/index.html
docs/generated/html/classes/<ClassName>.html
```

现有 `docs/index.html` 可以新增一个“Generated API”入口，指向生成目录；不要把 generated HTML 混进手写教程文档。

执行结果（2026-06-11）：

- 已新增 `tools/generate_api_html.py`，只读取 `docs/generated/xml/*.xml`，不重新解析 GDScript。
- 输出为 `docs/generated/html/index.html` 和 `docs/generated/html/classes/<ClassName>.html`。
- 当前 XML 渲染出 136 个 class HTML 页面，并跳过 Godot doctool 输出中不能作为 class page 渲染的插件脚本路径项。
- 已新增 `tools/check_generated_docs_fresh.py`，用于检查 HTML index、class page 和 XML mtime 的新鲜度。

### Phase 5: 替换 docs-check / CI

Makefile 最终形态建议：

```make
docs-api: docs-xml docs-html

docs-check:
	python3 tools/check_gd_doc_comments.py
	$(GODOT) --headless --path . --doctool /tmp/mkit_docs_xml_check --gdscript-docs res://addons/mkit
	python3 tools/check_generated_docs_fresh.py
	python3 tools/check_docs_sync.py
```

CI 静态检查建议：

```bash
make layering docs-check
```

执行结果（2026-06-11）：

- `Makefile` 已新增 `DOC_HTML_DIR`、`docs-html`、`docs-api`。
- `docs-check` 已改为依次运行 doc comment 覆盖检查、`make docs-api`、生成 freshness 检查和既有 docs 同步检查。
- `tools/check_docs_sync.py` 已移除旧 Markdown class ref 导航映射要求，只要求手写 Markdown 页面进入主导航。

### Phase 6: 删除旧手写 ref 维护面

完成 XML/HTML 生成并通过检查后：

- 删除旧 legacy kernel Markdown reference 和 legacy module Markdown reference，或将它们改成明确的 generated output。
- 更新 `docs/readme.md` 的 Reference 入口，指向 generated HTML。
- 更新 `docs/index.html` 导航，不再手动列出 100+ class ref Markdown。
- 更新 `AGENTS.md`：改 public API 时只改 `.gd` doc comment，再跑 `make docs-api` / `make docs-check`。

执行结果（2026-06-11）：

- `docs/index.html` 已新增 `Generated API HTML` 入口，指向 `generated/html/index.html`，并让 `.html` 导航项直接打开静态 HTML 页面。
- `docs/readme.md`、`docs/getting_started.md`、`docs/compatibility.md`、`docs/roadmap.md`、`docs/cookbook/*`、`docs/glossary.md` 的 reference 链接已迁到 generated HTML。
- `AGENTS.md` 已改为 `make docs-api` / `make docs-check` 工作流。
- 旧 Markdown reference 目录和旧自定义 Markdown generator 已退场。

## Cleanup Plan: 清理临时自定义生成链路

这一步的目标是先把当前临时的 Markdown ref 生成方案退场，避免 repo 同时存在两套 API 文档生成器。最终链路只能是：

```text
.gd ## doc comment
  -> Godot --doctool --gdscript-docs XML
  -> HTML
```

### 清理对象

| 对象 | 动作 | 时机 | 验证 |
|---|---|---|---|
| legacy Markdown generator | 删除；不保留自定义 GDScript parser 作为最终生成器 | 已完成 | 旧生成器不再存在 |
| `Makefile` 的 legacy ref target 目标 | 删除；改成 `docs-xml`, `docs-html`, `docs-api` | 已完成 | `make docs-check` 不再调用旧生成器 |
| `AGENTS.md`, `docs/readme.md`, `docs/getting_started.md` 中的 legacy ref target 说明 | 改成 Godot doctool/XML/HTML 链路 | 已完成 | 用户文档指向 `make docs-api` |
| legacy kernel Markdown reference, legacy module Markdown reference 中的 legacy generated Markdown header | 不作为长期来源；HTML 链路完成后删除 | 已完成 | `docs/index.html` 不再依赖这些 Markdown 页 |
| `.gitignore` 的 `__pycache__/` | 如果保留 Python 检查工具则保留；如果最终没有 Python docs 工具再删除 | 最终 docs-check 设计确定后 | `git status --ignored` 不暴露 Python cache |
| `tools/__pycache__/`, 临时 XML/HTML 输出 | 删除工作区缓存；生成 spike 输出只放 `/tmp` 或 ignored 目录 | 每次 spike 后 | `git status --short` 不出现缓存或临时产物 |

### 推荐清理顺序

1. **盘点当前临时改动**  
   先用精确路径确认 doc generation 相关 diff，避免误伤 P1-3 或其他用户改动：

   ```bash
   git diff --name-only -- Makefile AGENTS.md docs/readme.md docs/getting_started.md .gitignore
   rg "old markdown generator exact names"
   ```

2. **先跑 Godot doctool spike，不提交输出**  
   只把 XML 输出到 `/tmp` 或明确 ignored 的目录，确认 Godot 能收录 addon class、signal、property、method：

   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --doctool /tmp/mkit_docs_xml_spike --gdscript-docs res://addons/mkit
   ```

3. **Godot XML 可用后删除自定义 Markdown generator**  
   删除 legacy Markdown generator，同时从 `Makefile` 和文档说明里移除 legacy ref target。不要让 `docs-check` 同时跑 Godot doctool 和自定义 Markdown generator。

4. **恢复或冻结 legacy Markdown reference 的迁移角色**  
   如果旧手写 ref 内容仍需要用于回填 doc comment，则先保留它作为一次性迁移输入；如果已被临时 generator 批量覆盖，优先从 git 历史或当前 diff 中提取有价值的说明，再写回 `.gd ##`。迁移完成后，删除这些 Markdown 页或把它们明确标成非权威生成产物。

5. **重接 Makefile/docs-check/CI**  
   把文档检查改成 `check_gd_doc_comments.py` + Godot doctool XML freshness + 现有链接/导航检查。自定义逻辑只能检查覆盖率或渲染 XML，不能重新解析 GDScript 生成 API 权威内容。

6. **最终扫尾验证**  
   清理完成后至少跑：

   ```bash
   make docs-check
   python3 tools/check_layering.py
   git diff --check
   ```

   另跑一次旧管线精确名称扫描，确认旧 generator、旧 target 和旧 reference 路径没有残留。

### 清理护栏

- 不在 doc comment 回填完成前删除唯一还包含有效说明的旧 ref 内容。
- 不同时保留 legacy Markdown generator 和 Godot doctool 作为 active docs source。
- 不把 Godot doctool spike 输出提交进 repo，除非后续明确决定提交 generated HTML。
- 不让最终 API 文档从 Markdown 反推源码；Markdown 只能作为迁移材料。

## 验收标准

- `make docs-xml` 可重复运行，输出稳定。
- `make docs-html` 可打开，并能按 class 浏览 API。
- `make docs-check` 能发现缺失 doc comment。
- legacy Markdown reference 不再需要人工编辑。
- 改 public API 时，开发者只需要更新 `.gd` 声明和相邻 `##` doc comment。
- `make layering` 继续通过，确认 docs 工具没有引入 addon -> game 依赖。

执行结果（2026-06-11）：

- `make docs-check` 通过，并重新生成 Godot XML 与 136 个 API HTML class pages。
- `make layering` 通过。
- `git diff --check` 通过。
- 旧管线精确名称扫描无结果。

## 风险与处理

| 风险 | 影响 | 处理 |
|---|---|---|
| Godot doctool 对项目 GDScript 的收录规则不符合预期 | XML 不完整 | Phase 1 先做 spike，不进入批量迁移 |
| `ServiceRegistry` 无 `class_name`，可能不进 GDScript docs | 缺 autoload API 文档 | 评估给它补 `class_name`，或为 autoload 单独生成一页 |
| 官方 XML -> HTML 工具链过重 | CI 慢、依赖复杂 | 退到轻量 XML -> HTML renderer，但 renderer 不读源码 |
| 一次性补所有 doc comment 变成大 diff | review 困难 | 按 kernel / module 分批补，生成结果每批验证 |
| 注释和实现未来漂移 | 文档失真 | `check_gd_doc_comments` 只能查存在性；关键行为仍需测试和 code review |

## 推荐落地顺序

1. 做 Phase 1 spike：只加 `docs-xml`，确认 Godot XML 质量。
2. 写 `check_gd_doc_comments.py`，先只 report 不 fail。
3. 分批补 kernel doc comments。
4. 分批补 modules doc comments。
5. 接 HTML 生成。
6. docs-check 开始 fail 缺注释。
7. 删除或冻结旧手写 legacy Markdown reference。
