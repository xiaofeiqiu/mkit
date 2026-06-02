# GameCommand

## 概念说明

GameCommand 是表示"意图"的数据对象。负责承载 move、attack、cast_ability、interact、equip_item、select_reward 等来自玩家、AI、教程、自动测试或未来网络输入的请求。把意图和效果分开后，玩家输入和 AI 可以走同一条行为链路，测试也能直接发送命令验证系统。

## 设计目的

命令层将意图来源（玩家输入、AI、测试脚本）与处理者（StateMachine、AbilityController）完全解耦。命令只描述"想做什么"，不包含具体效果逻辑。

## 文件

`res://addons/mkit/kernel/commands/game_command.gd`

## 字段说明

- **command_id**：单次命令 ID。例：玩家连续点两次攻击时，两个 attack 命令需要能在 debug history 里分开追踪。
- **command_type**：命令类型。例：move、attack、cast_ability，StateMachine 根据它决定当前状态能不能处理。
- **source_id**：行为来源 ID。例：伤害事件里 source_id=player_001，Analytics 和仇恨系统就知道是谁造成了伤害。
- **target_id**：行为目标 ID。例：CastAbilityCommand 的 target_id=player_001 表示命令发给玩家实体处理，不是直接发给技能资源。
- **timestamp**：发生时间。例：DebugOverlay 可以按时间排序最近事件，回放系统也能按时间重放命令。
- **priority**：代码字段。计算优先级。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。
- **consumed**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。

## 接口

```gdscript
class_name GameCommand
extends RefCounted
var command_id: String = ""
var command_type: String = ""
var source_id: String = ""
var target_id: String = ""
var timestamp: float = 0.0
var priority: int = 0
var payload: Dictionary = {}
var consumed: bool = false
static func create( type: String, source: String = "", target: String = "", data: Dictionary = {} ) -> GameCommand
func mark_consumed() -> void
func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2
func get_string(key: String, default_value: String = "") -> String
func get_float(key: String, default_value: float = 0.0) -> float
```

## 函数使用场景

- **create()**：工厂方法，一次性设置 command_type、command_id、source_id、target_id、timestamp 和 payload。例：玩家按攻击键时创建 `GameCommand.create("attack", "player_001", "player_001", {"direction": dir})`。
- **mark_consumed()**：标记命令已处理。例：StateMachine 成功处理 attack 命令后标记 consumed，避免同一命令被后续系统重复处理。
- **get_vector2()**：从 payload 中安全读取 Vector2。例：MoveState 读取 `command.get_vector2("direction")` 获取移动方向。
- **get_string()**：从 payload 中安全读取 String。例：CastAbilityState 读取 `command.get_string("ability_id")` 获取技能 ID。
- **get_float()**：从 payload 中安全读取 float。例：读取技能释放时携带的数值型参数。

## 使用示例

### 玩家输入创建移动命令

```gdscript
func _physics_process(delta: float) -> void:
    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if dir != Vector2.ZERO:
        var cmd := GameCommand.create(
            BuiltinCommands.MOVE,
            "player_001",
            "player_001",
            {"direction": dir}
        )
        var router := ServiceRegistry.get_service("commands") as CommandRouter
        router.dispatch(cmd)
```

### 创建技能释放命令

```gdscript
func cast_fireball() -> void:
    var cmd := GameCommand.create(
        BuiltinCommands.CAST_ABILITY,
        "player_001",
        "player_001",
        {
            "ability_id": "ability.fireball_basic",
            "direction": Vector2.RIGHT
        }
    )
    ServiceRegistry.get_service("commands").dispatch(cmd)
```
