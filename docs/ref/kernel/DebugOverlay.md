# DebugOverlay

**层：** Kernel  
**文件：** `addons/mkit/kernel/debug/debug_overlay.gd`  
**继承：** `extends CanvasLayer`

## 职责

运行时调试浮层：实时显示已注册服务、被观察实体的当前状态路径、最近命令、HP，以及 `EventService` 最近事件。挂进场景即用。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `watch_entity_path` | `NodePath`（@export）| — | 要观察的实体（读其 StateMachine/HP/命令历史）|
| `status_provider_path` | `NodePath`（@export）| — | 可选：实现 `get_debug_status_lines()` 的自定义信息源 |
| `visible_on_start` | `bool`（@export）| `true` | 启动是否显示 |
| `show_registered_services` | `bool`（@export）| `true` | 是否列出所有服务 id |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `toggle() -> void` | — | 切换可见 |

> `_ready` 时把自己注册为 `"debug"` 服务。被观察实体需符合标准布局（`StateMachine` / `CommandReceiver` / `Components/HealthComponent`）。

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在场景里挂 DebugOverlay，Inspector 设 watch_entity_path = 玩家节点
# 想用按键开关：
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_debug"):
        (ServiceRegistry.get_port("debug") as DebugOverlay).toggle()
```

## 相关

- → [debugging.md](../../debugging.md)（配套调试手段）
- → [StateMachine](StateMachine.md)（`last_failed_transition_reason`）· [EventService](EventService.md)（`recent_events`）
