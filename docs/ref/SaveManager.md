# SaveManager

## 概念说明

SaveManager 是存档读写协调器。它收集 Saveable 数据、写文件、读文件、处理版本和迁移。玩家、背包、装备、Meta 进度和设置需要统一持久化入口。

## 设计目的

提供存档的统一入口，通过遍历场景树中的 Saveable 节点自动收集和分发数据，支持带版本号的存档格式和 SaveMigration 链式迁移，使各模块只需实现 Saveable 接口，不需要知道存档文件格式。

## 文件

`res://addons/mkit/kernel/save/save_manager.gd`

## 接口

```gdscript
class_name SaveManager
extends Node

signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)

@export var save_path: String = "user://save.json"
@export var save_version: int = 1
@export var game_version: String = "0.1.0"
@export var migrations: Array[SaveMigration] = []

func save_game(root: Node) -> bool: ...
func load_game(root: Node) -> bool: ...
func _collect_saveables(root: Node) -> Dictionary: ...
func _restore_saveables(root: Node, payload: Dictionary) -> void: ...
func _migrate_data(data: Dictionary) -> Dictionary: ...
func _find_migration(from_version: int, to_version: int) -> SaveMigration: ...
```

## 函数使用场景

- **`save_game(root)`**：遍历 root 下所有 Saveable 节点，调用 `to_save_data()` 收集数据，包装为带 save_version、timestamp 的 JSON 后写入 save_path。成功发出 `save_completed`，失败发出 `save_failed`。`root` 应传入 `get_tree().root` 以包含场景树外的长期节点（如 ProgressionSystem）。
- **`load_game(root)`**：读取 save_path 文件，解析 JSON，通过 `_migrate_data()` 按版本链升级存档结构，再遍历 root 下 Saveable 节点按 save_id 分发对应数据。
- **`_migrate_data(data)`**：内部方法，从存档的 save_version 开始，逐步查找并执行 SaveMigration，直到达到当前 save_version。
- **`_find_migration(from_version, to_version)`**：内部方法，在 migrations 列表中查找匹配版本对的 SaveMigration。

## 使用示例

### 保存游戏

```gdscript
func save_current_game() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    save_manager.save_game(get_tree().root)
```

### 读取游戏

```gdscript
func load_current_game() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    save_manager.load_game(get_tree().root)
```

### 监听结果

```gdscript
func _ready() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    save_manager.save_completed.connect(func(path): print("Saved: ", path))
    save_manager.load_completed.connect(func(path): print("Loaded: ", path))
    save_manager.save_failed.connect(func(path, reason): push_error(reason))
```
