# BuiltinCommands

**层：** Kernel  
**文件：** `addons/mkit/kernel/commands/builtin_commands.gd`  
**继承：** `extends Object`

## 职责

内置命令类型常量集合。`GameCommand.command_type` 用字符串标识意图，这里把常用意图集中成常量，避免散落的魔法字符串。

## 常量

| 常量 | 值 | 典型用途 |
|------|----|---------|
| `MOVE` | `"move"` | 移动（payload `direction: Vector2`）|
| `STOP_MOVE` | `"stop_move"` | 停止移动 |
| `ATTACK` | `"attack"` | 普通攻击 |
| `CAST_ABILITY` | `"cast_ability"` | 施放技能（payload `ability_id: String`）|
| `DASH` | `"dash"` | 冲刺 |
| `INTERACT` | `"interact"` | 交互 |
| `SELECT_REWARD` | `"select_reward"` | 选择奖励 |
| `OPEN_INVENTORY` | `"open_inventory"` | 打开背包 |
| `CLOSE_INVENTORY` | `"close_inventory"` | 关闭背包 |
| `EQUIP_ITEM` | `"equip_item"` | 装备 |
| `UNEQUIP_ITEM` | `"unequip_item"` | 卸下 |
| `PAUSE` | `"pause"` | 暂停 |
| `RESUME` | `"resume"` | 继续 |

> 注意是 `CAST_ABILITY`（不是 `USE_ABILITY`）。`command_type` 是普通 `String`，也可以用自定义字符串扩展，不限于这些常量。

## 使用模式

### 最小示例（Level 1）

```gdscript
var cmd := GameCommand.create(BuiltinCommands.CAST_ABILITY, "player", "player", {"ability_id": "fireball"})
(Mkit.commands()).dispatch(cmd)
```

```gdscript
# State.handle_command 里匹配
match command.command_type:
    BuiltinCommands.MOVE:
        return request_transition("Root/Move", {"direction": command.get_vector2("direction")})
    BuiltinCommands.ATTACK:
        return request_transition("Root/Attack")
```

## 相关

- → [GameCommand](GameCommand.md) · [CommandService](CommandService.md) · [CommandReceiver](CommandReceiver.md)
- → [cookbook/02_player_entity.md](../../cookbook/02_player_entity.md)
