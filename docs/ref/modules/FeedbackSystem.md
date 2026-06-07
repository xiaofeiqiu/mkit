# FeedbackSystem

**层：** Module  
**文件：** `addons/mkit/modules/ui/feedback_system.gd`  
**继承：** `extends Node`

## 职责

事件反馈桥。监听伤害和死亡事件，驱动伤害数字、VFX、音效、屏幕震动和 toast。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `damage_number_system_path` | `NodePath`（@export）| 空 | `DamageNumberSystem` 路径 |
| `vfx_spawner_path` | `NodePath`（@export）| 空 | `VFXSpawner` 路径 |
| `audio_manager_path` | `NodePath`（@export）| 空 | 可选的本地 `AudioService` 节点路径；不会自动从 `"audio"` 服务取 |
| `ui_manager_path` | `NodePath`（@export）| 空 | `UIManager` 路径 |
| `toast_screen_id` | `String`（@export）| `""` | toast screen id |
| `damage_screen_shake_strength` | `float`（@export）| `0.0` | 伤害震动强度 |
| `death_toast_template` | `String`（@export）| `""` | 死亡提示模板 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `show_toast(message: String) -> Node` | `Node` | 发 toast 信号，并可通过 `UIManager` 打开 screen |
| `request_screen_shake(strength: float = 1.0) -> void` | — | 发 `screen_shake_requested` |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `toast_requested` | `message` | `show_toast()` |
| `screen_shake_requested` | `strength` | `request_screen_shake()` |

## 使用模式

### 最小示例（Level 1）

```gdscript
$FeedbackSystem.show_toast("Quest complete")
```

### 典型场景（Level 2）

```gdscript
func bind_feedback() -> void:
    var feedback := $FeedbackSystem as FeedbackSystem
    feedback.screen_shake_requested.connect(func(strength: float) -> void:
        _shake_camera(strength)
    )
    feedback.toast_requested.connect(func(message: String) -> void:
        print(message)
    )
```

## 相关

- → [DamageNumberSystem](DamageNumberSystem.md) · [VFXSpawner](VFXSpawner.md) · [AudioService](../kernel/AudioService.md)
- → [pipeline.md — Animation — 事件反馈通道](../../pipeline.md#11-animation--事件反馈通道) · [cookbook/13_animation.md](../../cookbook/13_animation.md)
