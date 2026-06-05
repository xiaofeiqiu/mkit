# SimpleAIEnemyBrain

## 概念说明

SimpleAIEnemyBrain 是早期可用的简单敌人 AI。它发现目标、追击、进入攻击距离后攻击，否则停止或巡逻。在核心战斗稳定前，不应该先做复杂行为树；简单 AI 足够验证 vertical slice。

## 设计目的

提供一个开箱即用的基础敌人 AI，使开发团队可以在完成 HFSM 和 Combat 核心管线后立即看到可玩的敌人行为，而无需先实现完整的行为树或目标导向 AI。

## 文件

`res://addons/mkit/modules/ai/simple_ai_enemy_brain.gd`

## 字段说明

- **detection_range**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **attack_range**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **target_group**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name SimpleAIEnemyBrain
extends Brain
@export var detection_range: float = 240.0
@export var attack_range: float = 48.0
@export var target_group: String = "player"
func think() -> void
```

## 函数使用场景

- **`_ready()`**：调用父类 `_ready()` 后，立即从 `target_group` 中查找第一个目标节点（通常是玩家）并写入 `blackboard["target"]`。
- **`think()`**：每 `think_interval` 秒执行一次决策：
  - 目标在 `attack_range` 内：记录 `intent="attack"` 并发出 ATTACK 命令
  - 目标在 `detection_range` 内但超出攻击范围：记录 `intent="approach"` / `move_direction` 并发出 MOVE 命令
  - 目标在检测范围外：记录 `intent="idle"` 并发出 STOP_MOVE 命令

## 使用示例

### Enemy 场景挂载

```text
Goblin.tscn
  CharacterBody2D
    EntityIdentity
    CommandReceiver
    StateMachine
    Components
    Controllers
    AI
      SimpleAIEnemyBrain
```

### Inspector 配置

```text
SimpleAIEnemyBrain.detection_range = 240
SimpleAIEnemyBrain.attack_range = 48
SimpleAIEnemyBrain.target_group = "player"
```

### 运行时行为逻辑

```gdscript
func think() -> void:
    if target == null:
        return

    var owner_2d := owner as Node2D
    var target_2d := target as Node2D
    if owner_2d == null or target_2d == null:
        return

    var distance: float = owner_2d.global_position.distance_to(target_2d.global_position)

    if distance <= attack_range:
        issue_command(BuiltinCommands.ATTACK, {"target": target})
    elif distance <= detection_range:
        var direction: Vector2 = (target_2d.global_position - owner_2d.global_position).normalized()
        issue_command(BuiltinCommands.MOVE, {"direction": direction})
    else:
        issue_command(BuiltinCommands.STOP_MOVE, {})
```
