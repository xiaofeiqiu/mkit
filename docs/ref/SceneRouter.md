# SceneRouter

## 概念说明

SceneRouter 是场景切换服务。负责统一执行 change_scene、reload 等场景流，并发出切换信号。Bootstrap、RunDirector、死亡流程和 UI 都可能需要换场景；如果到处直接调用 `get_tree().change_scene_to_file()`，存档、淡入淡出和清理顺序会很难统一。

## 设计目的

集中管理所有场景切换，避免重复切换和无效路径导致的运行时错误。通过信号通知外部系统切换前后的状态，方便实现淡入淡出等过渡效果。

## 文件

`res://addons/mkit/kernel/services/scene_router.gd`

## 接口

```gdscript
class_name SceneRouter
extends Node

signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal scene_change_failed(scene_path: String, reason: String)

var current_scene_path: String = ""
var transition_locked: bool = false

func change_scene(scene_path: String) -> bool

func reload_current_scene() -> bool
```

## 函数使用场景

- **change_scene()**：切换场景入口。例：RunDirector 结束 run 后通过此方法切到结算界面，GameBootstrap 启动完成后切到主菜单。
- **reload_current_scene()**：重载当前场景。例：Debug 菜单中快速重开当前测试场景。

## 使用示例

### 切换到主菜单

```gdscript
var scenes := ServiceRegistry.get_service("scenes") as SceneRouter
scenes.change_scene("res://game/scenes/main_menu.tscn")
```

### 监听切换事件

```gdscript
func _ready() -> void:
    var scenes := ServiceRegistry.get_service("scenes") as SceneRouter
    scenes.scene_changed.connect(_on_scene_changed)
    scenes.scene_change_failed.connect(_on_scene_failed)

func _on_scene_changed(path: String) -> void:
    print("Scene loaded: ", path)

func _on_scene_failed(path: String, reason: String) -> void:
    push_error("Scene change failed: %s reason: %s" % [path, reason])
```
