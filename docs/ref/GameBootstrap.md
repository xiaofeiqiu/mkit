# GameBootstrap

## 概念说明

GameBootstrap 是 Mkit 的启动编排器。负责创建服务、注册服务、加载资源数据库、校验内容、初始化运行时系统并进入初始场景。Godot 项目的启动顺序如果靠节点 ready 顺序隐式决定，很容易出现偶发 bug；Bootstrap 让启动过程可读、可测、可复现。

## 设计目的

按固定顺序依次执行：创建核心服务 → 注册服务 → 加载资源数据库 → 校验 ContentRegistry → 加载存档或创建 profile → 进入初始场景。任何需要保证启动顺序的逻辑都应当在此协调，而不是散落在各节点的 `_ready()` 中。

## 文件

`res://addons/mkit/kernel/bootstrap/game_bootstrap.gd`

## 字段说明

- **resource_databases**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **initial_scene_path**：初始场景资源路径，必须是可加载的 `PackedScene`。不得与挂载本 `GameBootstrap` 的场景相同，否则触发无限重载保护并 `push_error` 中止。空字符串时 `_enter_initial_scene()` 直接跳过。

## 接口

```gdscript
class_name GameBootstrap
extends Node
@export var resource_databases: Array[ResourceDatabase] = []
@export var initial_scene_path: String = ""
func boot() -> void
```

## 函数使用场景

- **boot()**：公开启动流程入口。依次调用内部六个步骤，确保服务注册、内容加载、内容校验、运行时初始化、存档读取和进入初始场景按顺序发生。
- **_register_kernel_services()**：内部辅助。创建 EventRouter、ContentRegistry、RandomService、TimeService、ActionRunner、EffectExecutor、CommandRouter、SceneRouter、SaveManager、ProgressionSystem、ObjectPool、QuestSystem、ShopController、AudioManager、DialogueController、WorldRouter 和平台 mock services，并注册到 ServiceRegistry。
- **_load_content()**：内部辅助。遍历 `resource_databases`，对每个 ResourceDatabase 调用 ContentRegistry.load_database。
- **_validate_content()**：内部辅助。调用 ContentRegistry.validate_all，若失败则 push_error，防止带有重复 ID 的内容进入游戏。
- **_initialize_runtime_systems()**：内部辅助。游戏特定的运行时初始化扩展点，默认为空。
- **_load_profile()**：内部辅助。若 `"save"` 服务已注册且 `save_manager.save_path` 文件存在，则调用 `save_manager.load_game(get_tree().root)` 自动读档；否则跳过。子类可覆盖此方法在读档前后执行额外逻辑。
- **_enter_initial_scene()**：内部辅助。验证 `initial_scene_path` 指向已存在的 `PackedScene` 且不与当前场景相同后，通过 SceneRouter（或 `get_tree().change_scene_to_file`）切换到初始场景。

## 使用示例

### Main 场景挂载 GameBootstrap

```text
Main.tscn
  GameBootstrap
```

### Inspector 配置

```text
GameBootstrap.resource_databases = [
  res://game/content/items/item_database.tres,
  res://game/content/abilities/ability_database.tres,
  res://game/content/rooms/room_database.tres
]

GameBootstrap.initial_scene_path = "res://game/scenes/main_menu.tscn"
```

### 典型启动流程

```gdscript
func boot() -> void:
    _register_kernel_services()
    _load_content()
    _validate_content()
    _initialize_runtime_systems()
    _load_profile()
    _enter_initial_scene()
```
