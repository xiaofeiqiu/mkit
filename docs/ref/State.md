# State

## 概念说明

State 是 HFSM（层级有限状态机）中的一个行为模式节点。负责处理 enter、exit、update、physics_update、命令响应、守卫条件和状态转换请求。Idle、Move、Attack、Cast、Dead、Paused 等行为如果混在一个脚本里会很难维护，拆成状态后逻辑边界更清楚。

## 设计目的

每个 State 封装一种行为模式，通过组合 State 树形成 HFSM。父状态可以拦截命令，子状态处理具体行为，转换通过 request_transition 统一走 StateMachine 管理。

## 文件

`res://addons/mkit/kernel/state_machine/state.gd`

## 字段说明

- **state_id**：稳定 ID 字段。例：State 通过 state_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **initial_child_state_id**：稳定 ID 字段。例：State 通过 initial_child_state_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **parent_state**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **state_machine**：所属状态机引用。例：AttackState 完成后通过 state_machine 请求回到 Idle。
- **owner_entity**：拥有该组件或状态机的实体。例：PlayerMoveState 需要通过 owner_entity 读取 StatsComponent 并推动 CharacterBody2D。
- **active_child**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **blackboard**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name State
extends Node
@export var state_id: String = ""
@export var initial_child_state_id: String = ""
var parent_state: State = null
var state_machine: StateMachine = null
var owner_entity: Node = null
var active_child: State = null
var blackboard: Blackboard = null
func setup(machine: StateMachine, entity: Node, parent: State = null) -> void
func enter(context: Dictionary = {}) -> void
func exit(context: Dictionary = {}) -> void
func update(delta: float) -> void
func physics_update(delta: float) -> void
func handle_command(command: GameCommand) -> bool
func can_enter(context: Dictionary = {}) -> bool
func can_exit(context: Dictionary = {}) -> bool
func request_transition(target_path: String, context: Dictionary = {}) -> bool
func get_path_ids() -> Array[String]
func get_full_path() -> String
```

## 函数使用场景

- **enter()**：进入状态时调用。例：BasicAttackState 进入时播放攻击动画并启动 TimedAttackAction。
- **exit()**：离开状态时调用。例：DashState 退出时关闭无敌标记、清理移动输入。
- **update()**：每帧逻辑更新。例：CastAbilityState 每帧检查施法进度。
- **physics_update()**：物理帧更新。例：MoveState 在这里读取方向并调用 move_and_slide。
- **handle_command()**：处理命令，返回是否处理成功。例：MoveState 收到 attack 命令时请求切到 BasicAttack 状态。
- **can_enter()**：进入前守卫检查。例：CastAbilityState 只在冷却完成时才允许进入。
- **can_exit()**：退出前守卫检查。例：Dead 状态默认不允许退出，除非复活流程传入 allow_revive=true。
- **request_transition()**：请求状态机执行转换。例：AttackState 攻击动作完成后请求回到 Idle。
- **get_full_path()**：获取当前状态完整路径。例：DebugOverlay 读取路径显示为 "Player/Alive/Combat/BasicAttack"。

## 使用示例

### Idle State

```gdscript
class_name PlayerIdleState
extends State

func enter(context: Dictionary = {}) -> void:
    owner_entity.velocity = Vector2.ZERO
    print("Enter Idle")

func handle_command(command: GameCommand) -> bool:
    if command.command_type == BuiltinCommands.MOVE:
        blackboard.set_value("move_direction", command.get_vector2("direction"))
        return request_transition("Player/Alive/Locomotion/Move", {"reason": "move"})

    if command.command_type == BuiltinCommands.ATTACK:
        return request_transition("Player/Alive/Combat/BasicAttack", {
            "reason": "attack",
            "command": command
        })

    return false
```

### Dead State（带退出守卫）

```gdscript
class_name PlayerDeadState
extends State

func enter(context: Dictionary = {}) -> void:
    owner_entity.velocity = Vector2.ZERO
    var anim := owner_entity.get_node("Presentation/AnimationPlayer") as AnimationPlayer
    anim.play("death")

func can_exit(context: Dictionary = {}) -> bool:
    return context.get("allow_revive", false)
```
