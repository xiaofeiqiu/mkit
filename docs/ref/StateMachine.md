# StateMachine

## 概念说明

StateMachine 是当前行为状态和状态转换的拥有者。负责注册状态、跟踪当前状态路径、分发命令和 update、执行合法转换并暴露调试信息。玩家、敌人、房间和 Run 都会有复杂状态，统一 StateMachine 能减少大量布尔变量组合。

## 设计目的

提供层级有限状态机（HFSM）实现，通过最低公共祖先（LCA）算法精确退出/进入状态链，保证 exit/enter 调用顺序可预测。所有状态转换都有合法性检查，失败时通过信号和字段暴露原因。

## 文件

`res://addons/mkit/kernel/state_machine/state_machine.gd`

## 接口

```gdscript
class_name StateMachine
extends Node

signal state_changed(previous_path: String, current_path: String)
signal transition_failed(from_path: String, to_path: String, reason: String)

@export var initial_state_path: String = ""
@export var auto_start: bool = true

var owner_entity: Node = null
var root_state: State = null
var current_leaf_state: State = null
var blackboard: Blackboard = Blackboard.new()
var previous_path: String = ""
var last_transition_reason: String = ""
var last_failed_transition_reason: String = ""

func handle_command(command: GameCommand) -> bool

func transition_to(target_path: String, context: Dictionary = {}) -> bool

func get_current_path() -> String

func find_state_by_path(path: String) -> State
```

## 函数使用场景

- **handle_command()**：将命令从当前叶节点状态向上冒泡处理。例：CommandReceiver 收到命令后调用 `state_machine.handle_command(cmd)`，由当前状态决定如何响应。
- **transition_to()**：执行状态转换。例：HealthComponent 检测 HP 归零后调用 `sm.transition_to("Player/Dead", {"reason": "hp_zero"})`。
- **get_current_path()**：读取当前状态路径字符串。例：DebugOverlay 每帧读取此路径并显示。
- **find_state_by_path()**：根据路径字符串查找状态节点。例：在外部系统中获取特定状态节点的引用。

## 使用示例

### 场景结构

```text
Player.tscn
  StateMachine
    Player
      Alive
        Locomotion
          Idle
          Move
          Dash
        Combat
          BasicAttack
          CastAbility
      Dead
```

### 初始化状态

```gdscript
func _ready() -> void:
    var sm := $StateMachine as StateMachine
    sm.initial_state_path = "Player/Alive/Locomotion/Idle"
    sm.state_changed.connect(_on_state_changed)

func _on_state_changed(previous: String, current: String) -> void:
    print("State changed: %s -> %s" % [previous, current])
```

### 强制切换到死亡状态

```gdscript
func _on_health_died(owner_entity: Node) -> void:
    var sm := owner_entity.get_node("StateMachine") as StateMachine
    sm.transition_to("Player/Dead", {"reason": "hp_zero"})
```
