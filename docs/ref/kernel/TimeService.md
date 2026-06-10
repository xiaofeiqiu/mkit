# TimeService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/time_service.gd`  
**继承：** `extends RefCounted`  
**服务 ID：** `"time"`

## 职责

游戏时间与暂停的统一来源。`ActionService` 用 `get_scaled_delta()` 推进动作，从而暂停/慢动作只需改一处。`UIManager` 打开 modal 界面时通过它暂停游戏。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `paused` | `bool` | `false` | 暂停时 `get_scaled_delta` 返回 0 |
| `gameplay_time_scale` | `float` | `1.0` | 时间缩放（慢动作/加速）|
| `elapsed_gameplay_time` | `float` | `0.0` | 累计游戏时间（`advance` 累加）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `set_paused(value: bool) -> void` | — | 设暂停 |
| `set_gameplay_time_scale(value: float) -> void` | — | 设缩放（下限 0）|
| `get_scaled_delta(delta: float) -> float` | `float` | 暂停→0，否则 `delta * scale` |
| `advance(delta: float) -> float` | `float` | 累加 `elapsed_gameplay_time` 并返回缩放后 delta |
| `get_unix_time() -> int` | `int` | 系统 Unix 时间 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var time := Mkit.time()
time.set_paused(true)              # 暂停（动作停止推进）
time.set_gameplay_time_scale(0.3)  # 子弹时间
```

## 相关

- → [ActionService](ActionService.md)（用 `get_scaled_delta` 推进）· [ref/modules/UIManager.md](../modules/UIManager.md)（modal 暂停）
