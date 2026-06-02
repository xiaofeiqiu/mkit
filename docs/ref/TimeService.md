# TimeService

## 概念说明

TimeService 是玩法时间的统一包装。负责提供 scaled/unscaled delta、暂停状态和时间缩放，不直接替代 Godot 的 Time 单例。Action、状态效果、AI 思考和 UI 动画对暂停的要求不同；统一服务可以避免暂停菜单打开时战斗和冷却继续跑。

## 设计目的

将玩法时间流逝与 Godot 引擎真实时间解耦，使暂停、慢动作等时间操作能统一影响所有依赖 TimeService 的系统。保存 elapsed_gameplay_time 以支持 run 用时统计。

## 文件

`res://addons/mkit/kernel/services/time_service.gd`

## 接口

```gdscript
class_name TimeService
extends RefCounted

var paused: bool = false
var gameplay_time_scale: float = 1.0
var elapsed_gameplay_time: float = 0.0

func set_paused(value: bool) -> void

func set_gameplay_time_scale(value: float) -> void

func get_scaled_delta(delta: float) -> float

func advance(delta: float) -> float

func get_unix_time() -> int
```

## 函数使用场景

- **set_paused()**：设置暂停状态。例：UIManager 打开 modal 奖励界面时调用 `set_paused(true)`，关闭时调用 `set_paused(false)`。
- **set_gameplay_time_scale()**：设置时间倍率。例：子弹时间特效将倍率设为 0.25，实现慢动作效果。
- **get_scaled_delta()**：读取缩放后的 delta。例：ActionRunner 在 `_process` 中用缩放 delta 更新 Action，暂停时 delta 为 0。
- **advance()**：推进玩法时间并累计到 elapsed_gameplay_time。例：RunDirector 每帧调用以记录本局用时。
- **get_unix_time()**：读取系统真实时间。例：SaveManager 写入存档时间戳时使用。

## 使用示例

### 暂停与恢复玩法时间

```gdscript
var time := ServiceRegistry.get_service("time") as TimeService
time.set_paused(true)

func _process(delta: float) -> void:
    var scaled_delta := time.advance(delta)
    print("Gameplay advanced by: ", scaled_delta)
```
