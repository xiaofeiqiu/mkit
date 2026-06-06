# DebugOverlay

## 概念说明

DebugOverlay 是运行时调试叠层（CanvasLayer）。负责显示当前被观察实体的 HFSM 状态路径、HP、最近一次命令、EventRouter 的最近事件、已注册服务，以及可选状态提供者返回的调试行。它不是 autoload，由 GameBootstrap 或 Main 场景创建并注册为 `"debug"` 服务（class_name 不与任何 autoload 冲突）。

## 设计目的

提供"命令 → 状态 → 动作 → 效果 → 事件"链路的实时可视化，辅助调试和验证。DebugOverlay 只读取状态，不修改任何 gameplay 逻辑，关闭它不影响游戏运行。

## 文件

`res://addons/mkit/kernel/debug/debug_overlay.gd`

## 字段说明

- **watch_entity_path**：要观察的实体（通常是玩家）。
- **status_provider_path**：可选调试状态提供者。若节点有 `get_debug_status_lines()` 方法，Overlay 会附加其返回内容。
- **visible_on_start**：是否启动即显示，可用快捷键 toggle。
- **show_registered_services**：是否显示 ServiceRegistry 当前注册的 service_id。

## 接口

```gdscript
class_name DebugOverlay
extends CanvasLayer
@export var watch_entity_path: NodePath
@export var status_provider_path: NodePath
@export var visible_on_start: bool = true
@export var show_registered_services: bool = true
func toggle() -> void
```

## 函数使用场景

- **toggle()**：切换调试叠层显示状态。例：绑定一个快捷键，开发时随时显示或隐藏调试信息。
- **`_build_text()`**：内部文本生成方法。读取 watched entity、EventRouter、ServiceRegistry，并调用状态提供者的 `get_debug_status_lines()`，用于显示当前 zone、run 状态等 demo 侧信息但不引入 kernel→module 依赖。

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
