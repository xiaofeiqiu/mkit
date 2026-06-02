# PlayerInputReader

## 概念说明

PlayerInputReader 是玩家输入到游戏命令的转换层。它在每个物理帧读取 Godot Input，将方向移动、攻击和技能按键转换为对应的 GameCommand，并通过 CommandRouter 派发给玩家实体。输入层与游戏逻辑彻底解耦：换成 AI 或网络命令时上层逻辑不变。

## 设计目的

把玩家按键和摇杆输入的读取逻辑集中到一个节点，统一转换为 GameCommand 并通过 CommandRouter 分发，使 HFSM、战斗、技能系统完全不需要了解 Input 类，也方便自动化测试直接发送命令代替按键操作。

## 文件

由使用者自行实现（框架提供参考实现，位于 Spec 12）

## 接口

```gdscript
class_name PlayerInputReader
extends Node

@export var player_entity_id: String = "player_001"

func _physics_process(delta: float) -> void: ...
```

## 函数使用场景

- **`_physics_process(delta)`**：每物理帧读取输入：
  - 方向键/摇杆产生 `MOVE` 命令（含 direction Vector2）
  - 攻击键按下产生 `ATTACK` 命令（含当前面朝方向）
  - 技能键按下产生 `CAST_ABILITY` 命令（含 ability_id 和 direction）
  - 互动键按下产生 `INTERACT` 命令

## 使用示例

```gdscript
class_name PlayerInputReader
extends Node

@export var player_entity_id: String = "player_001"

func _physics_process(delta: float) -> void:
    var router := ServiceRegistry.get_service("commands") as CommandRouter

    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction != Vector2.ZERO:
        router.dispatch(GameCommand.create(
            BuiltinCommands.MOVE,
            player_entity_id,
            player_entity_id,
            {"direction": direction}
        ))

    if Input.is_action_just_pressed("attack"):
        router.dispatch(GameCommand.create(
            BuiltinCommands.ATTACK,
            player_entity_id,
            player_entity_id,
            {"direction": direction if direction != Vector2.ZERO else Vector2.RIGHT}
        ))

    if Input.is_action_just_pressed("ability_1"):
        router.dispatch(GameCommand.create(
            BuiltinCommands.CAST_ABILITY,
            player_entity_id,
            player_entity_id,
            {
                "ability_id": "ability.fireball_basic",
                "direction": direction if direction != Vector2.ZERO else Vector2.RIGHT
            }
        ))
```
