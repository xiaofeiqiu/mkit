# SimpleAIEnemyBrain

**层：** Module  
**文件：** `addons/mkit/modules/ai/simple_ai_enemy_brain.gd`  
**继承：** `extends Brain`

## 职责

开箱即用的简单近战 AI：按与目标的距离决定 Idle / 追击 / 攻击，并把决策写进 `blackboard.intent`。无需写代码，配好范围即用。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `detection_range` | `float`（@export）| `240.0` | 进入此范围开始追击 |
| `attack_range` | `float`（@export）| `48.0` | 进入此范围发起攻击 |
| `target_group` | `String`（@export）| `"player"` | 用 `get_first_node_in_group` 找目标 |

## 决策逻辑（`think`）

| 距离 | 行为 | 发出命令 |
|------|------|---------|
| `≤ attack_range` | 攻击 | `ATTACK` |
| `≤ detection_range` | 追击 | `MOVE`（朝目标）|
| `> detection_range` | 待机 | `STOP_MOVE` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在敌人 Controllers/ 下挂 SimpleAIEnemyBrain，Inspector 配：
#   detection_range = 240, attack_range = 48, target_group = "player"
# 玩家节点需加入 "player" group
```

## 相关

- → [Brain](Brain.md)（基类）· [cookbook/06_ai_enemy.md](../../cookbook/06_ai_enemy.md)
