# Recipe 01：游戏启动，services 在线  ·  难度 ★☆☆  ·  预计 15 分钟

## 本篇结束后，你的项目新增了什么

运行场景后，控制台打印所有已注册服务 ID（`events`、`content`、`actions`…），无报错。游戏框架已启动，kernel 服务就绪。

## 前置

- 需完成：[getting_started.md](../getting_started.md)（Godot 4.x，`addons/mkit/` 已启用，`ServiceRegistry` 已加 autoload）
- 用到的概念：[concepts.md — 模型 3：内容注册与查询](../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)

## 你负责 / mkit 负责

| 你写的 | mkit 处理的 |
|--------|------------|
| 新建 Bootstrap 场景，挂 `GameBootstrap` 节点 | 注册 kernel 服务（events、actions、effects…）|
| 设 `resource_databases` 数组 | 加载并校验所有 ContentDefinition |
| 设 `initial_scene_path` | 启动完成后切入游戏场景 |
| （可选）继承 `GameBootstrap`，override `_register_kernel_services` 添加自定义服务 | 其余启动步骤 |

## 步骤

### 步骤 1：创建 ResourceDatabase

1. 在编辑器的文件系统面板，右键 → New Resource → 选 `ResourceDatabase`
2. 保存为 `res://data/main_database.tres`
3. 在 Inspector 中：
   - `database_id` = `"main"`
   - `resources` 暂时留空（后续 Recipe 会添加内容）

### 步骤 2：创建 Bootstrap 场景

1. 新建场景 → 根节点选 `Node`（或继承 `GameBootstrap`）
2. 在根节点上附加脚本（或直接选 `GameBootstrap` 作为脚本类型）

**方式 A：直接挂 GameBootstrap（推荐入门）**

在场景根节点选 Script → 选 `GameBootstrap`（内置类）即可，无需写代码。

然后在 Inspector 配置：
- `resource_databases` → 添加 `res://data/main_database.tres`
- `initial_scene_path` → 留空（此阶段只验证启动）
- 需要内置 gameplay 模块时，改挂 `ModuleBootstrap`

**方式 B：继承 GameBootstrap（需要自定义服务）**

```gdscript
# res://game/bootstrap/my_bootstrap.gd
class_name MyBootstrap
extends GameBootstrap

func _register_kernel_services() -> void:
    super._register_kernel_services()           # 先注册所有内置服务
    var my_svc := MyCustomService.new()
    ServiceRegistry.register_service("my_svc", my_svc)
```

### 步骤 3：添加启动验证代码

在场景根节点（或继承类）添加以下验证，确认服务就绪：

```gdscript
# res://game/bootstrap/my_bootstrap.gd
extends GameBootstrap

func _ready() -> void:
    super._ready()     # 触发 boot()
    _verify_services()


func _verify_services() -> void:
    var ids := ServiceRegistry.get_registered_service_ids()
    print("=== mkit services online ===")
    for id in ids:
        print("  [OK] %s" % id)
    print("============================")

    # 如果需要在首屏显示服务列表：
    if ServiceRegistry.get_port(ContentService.SERVICE_ID) == null:
        push_error("ContentService missing — check GameBootstrap setup")
```

### 步骤 4：将 Bootstrap 场景设为主场景

编辑器 → Project Settings → Application → Run → Main Scene → 选 Bootstrap 场景。

## 运行验证

按 F5 运行。控制台应输出：

```
=== mkit services online ===
  [OK] actions
  [OK] audio
  [OK] commands
  [OK] content
  [OK] effects
  [OK] events
  [OK] pool
  [OK] random
  [OK] save
  [OK] scenes
  [OK] time
============================
```

无 `push_error` 或 `push_warning` 输出即为成功。

若使用 `ModuleBootstrap`，输出会额外包含 `combat`、`dialogue`、`loot`、`progression`、`quest`、`shop`、`world`。

## 常见错误

| 现象 | 原因 | 修复 |
|------|------|------|
| `ServiceRegistry autoload is missing` | 未将 `ServiceRegistry` 加为 autoload | Project Settings → AutoLoad → 添加 `addons/mkit/kernel/services/service_registry.gd`，命名为 `ServiceRegistry` |
| `Content validation failed` | ResourceDatabase 中有 `ContentDefinition` 的 `get_content_id()` 返回空串 | 确认每个 `.tres` 的 ID 字段非空且唯一 |
| `initial_scene_path ... points to the scene that already contains this GameBootstrap` | Bootstrap 场景的 `initial_scene_path` 指向了自身 | 将 `initial_scene_path` 改为另一个场景，或留空 |
| `ServiceRegistry.get_port(ContentService.SERVICE_ID)` 返回 null | 在 `_ready` 中过早访问服务（Bootstrap 还未执行）| 确保 Bootstrap 场景是第一个运行的场景 |

## 延伸阅读

- [ServiceRegistry ref](../generated/html/classes/ServiceRegistry.html) — 注册、获取、检查服务的完整 API
- [GameBootstrap ref](../generated/html/classes/GameBootstrap.html) — 启动时序的所有 override 点
- [ResourceDatabase ref](../generated/html/classes/ResourceDatabase.html) — 内容数据库结构
- [pipeline.md — Runtime Bootstrap](../pipeline.md#1-runtime-bootstrap) — 启动时序完整流程图
