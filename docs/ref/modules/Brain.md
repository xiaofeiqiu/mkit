# Brain

**层：** Module  
**文件：** `addons/mkit/modules/ai/brain.gd`  
**继承：** `extends Node`

## 职责

AI 决策基类，挂在实体 `Controllers/` 下。按 `think_interval` 周期调用 `think()`；子类在 `think()` 里用 `issue_command()` 给自身实体发命令（MOVE/ATTACK…），命令再走标准的 `CommandService → StateMachine` 管线——AI 与玩家共用同一套行为入口。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `enabled` | `bool`（@export）| `true` | 是否决策 |
| `think_interval` | `float`（@export）| `0.2` | 决策间隔秒（务必 `>0`）|
| `target` | `Node` | `null` | 当前目标 |
| `blackboard` | `Blackboard` | 新建 | 决策黑板（存意图/距离等）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `think() -> void` | — | **子类实现** 决策逻辑，默认空 |
| `issue_command(command_type, payload := {}) -> bool` | `bool` | 给自身实体发命令 |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name PatrolBrain
extends Brain

func think() -> void:
    issue_command(BuiltinCommands.MOVE, {"direction": Vector2.LEFT})
```

## 相关

- → [SimpleAIEnemyBrain](SimpleAIEnemyBrain.md)（内置实现）· [Blackboard](../kernel/Blackboard.md)
- → [cookbook/06_ai_enemy.md](../../cookbook/06_ai_enemy.md)
