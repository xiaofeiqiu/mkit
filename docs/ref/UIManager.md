# UIManager

## 概念说明

UIManager 是 UI 屏幕和弹窗的管理器。它负责打开/关闭界面、堆叠弹窗、阻塞 gameplay 输入并处理暂停。UI 不应该直接控制玩法系统，但需要统一管理屏幕流。

## 设计目的

提供一个统一的 UI 屏幕生命周期管理器，使所有界面的打开/关闭都通过同一入口，保证 modal 界面正确暂停 gameplay 时间，并防止同一屏幕被重复打开。

## 文件

`res://addons/mkit/modules/ui/ui_manager.gd`

## 接口

```gdscript
class_name UIManager
extends Node

signal screen_opened(screen_id: String)
signal screen_closed(screen_id: String)

@export var screen_root_path: NodePath = NodePath("ScreenRoot")
@export var screen_scene_map: Dictionary = {}

var screen_stack: Array[String] = []
var active_screens: Dictionary = {}
var modal_screens: Array[String] = []

func open_screen(screen_id: String, data: Dictionary = {}, modal: bool = false) -> Node: ...
func close_screen(screen_id: String) -> void: ...
func close_top_screen() -> void: ...
func is_screen_open(screen_id: String) -> bool: ...
```

## 函数使用场景

- **`open_screen(screen_id, data, modal)`**：打开指定屏幕，从 `screen_scene_map` 加载 PackedScene，实例化后若屏幕有 `setup()` 方法则传入 data。`modal=true` 时将屏幕加入 modal_screens 并通过 TimeService 暂停 gameplay。同一屏幕已打开时直接返回现有实例。RunDirector 在清房间后调用此方法打开奖励选择界面。
- **`close_screen(screen_id)`**：关闭指定屏幕，调用 `queue_free()`，从 screen_stack 和 modal_screens 移除；若 modal_screens 全部关闭则恢复 gameplay 时间。
- **`close_top_screen()`**：关闭当前最顶层的屏幕，适用于 Esc 键关闭逻辑。
- **`is_screen_open(screen_id)`**：查询指定屏幕是否已打开，防止重复打开或在屏幕不存在时执行操作。

## 使用示例

### 打开背包

```gdscript
func open_inventory() -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("inventory", {"owner_id": "player_001"}, true)
```

### 打开奖励选择

```gdscript
func show_rewards(options: Array[RewardOption], run_director: RunDirector) -> void:
    var ui := ServiceRegistry.get_service("ui") as UIManager
    ui.open_screen("reward_selection", {
        "options": options,
        "run_director": run_director
    }, true)
```

### 关闭顶部 UI

```gdscript
if Input.is_action_just_pressed("ui_cancel"):
    $UIManager.close_top_screen()
```
