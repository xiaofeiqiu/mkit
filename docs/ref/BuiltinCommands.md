# BuiltinCommands

## 概念说明

BuiltinCommands 是内置命令类型名称的常量表。负责集中定义 move、attack、cast_ability、dash、interact、select_reward、open_inventory、equip_item 等通用命令字符串，避免各处散落裸字符串。

## 设计目的

通过常量表统一所有通用命令名称，确保输入层、AI 层、状态机之间使用完全一致的命令标识符。重命名命令时只需修改常量和对应处理点，不需要搜索整个项目。

## 文件

`res://addons/mkit/kernel/commands/builtin_commands.gd`

## 接口

```gdscript
class_name BuiltinCommands
extends Object
const MOVE := "move"
const STOP_MOVE := "stop_move"
const ATTACK := "attack"
const CAST_ABILITY := "cast_ability"
const DASH := "dash"
const INTERACT := "interact"
const SELECT_REWARD := "select_reward"
const OPEN_INVENTORY := "open_inventory"
const CLOSE_INVENTORY := "close_inventory"
const EQUIP_ITEM := "equip_item"
const UNEQUIP_ITEM := "unequip_item"
const PAUSE := "pause"
const RESUME := "resume"
```

## 函数使用场景

BuiltinCommands 只包含常量，没有函数。在所有需要命令类型字符串的地方直接引用常量。

## 使用示例

### 在 StateMachine 中匹配命令类型

```gdscript
match command.command_type:
    BuiltinCommands.MOVE:
        _handle_move(command)
    BuiltinCommands.ATTACK:
        _handle_attack(command)
    BuiltinCommands.CAST_ABILITY:
        _handle_cast(command)
    BuiltinCommands.INTERACT:
        _handle_interact(command)
```

### 在 Brain 中发出命令

```gdscript
issue_command(BuiltinCommands.ATTACK, {"target": target})
```
