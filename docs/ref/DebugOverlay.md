# DebugOverlay

## 概念说明

DebugOverlay 是运行时调试叠层（CanvasLayer）。负责显示当前被观察实体的 HFSM 状态路径、HP、最近一次命令，以及 EventRouter 的最近事件。它不是 autoload，由 GameBootstrap 或 Main 场景创建并注册为 `"debug"` 服务（class_name 不与任何 autoload 冲突）。

## 设计目的

提供"命令 → 状态 → 动作 → 效果 → 事件"链路的实时可视化，辅助调试和验证。DebugOverlay 只读取状态，不修改任何 gameplay 逻辑，关闭它不影响游戏运行。

## 文件

`res://addons/mkit/kernel/debug/debug_overlay.gd`

## 接口

```gdscript
class_name DebugOverlay
extends CanvasLayer

@export var watch_entity_path: NodePath
@export var visible_on_start: bool = true

var _label: Label = null
var _events: EventRouter = null

func _ready() -> void

func _process(_delta: float) -> void

func toggle() -> void
```

## 函数使用场景

- **toggle()**：切换调试叠层显示状态。例：绑定一个快捷键，开发时随时显示或隐藏调试信息。

## 使用示例

### 在 Main 场景中创建 DebugOverlay

```gdscript
var overlay := DebugOverlay.new()
overlay.watch_entity_path = player.get_path()
add_child(overlay)
```

### 绑定切换快捷键

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("toggle_debug"):
        var debug := ServiceRegistry.get_service("debug") as DebugOverlay
        if debug != null:
            debug.toggle()
```
