class_name BuiltinCommands
extends Object
## 说明：`BuiltinCommands` 是 命令路由 的内置命令目录，负责集中定义常用 GameCommand 类型常量。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在命令路由中复用这段契约或状态时使用它。
## 示例：`var instance := BuiltinCommands.new()`

## 公开常量 `MOVE`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const MOVE := "move"
## 公开常量 `STOP_MOVE`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const STOP_MOVE := "stop_move"
## 公开常量 `ATTACK`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const ATTACK := "attack"
## 公开常量 `CAST_ABILITY`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const CAST_ABILITY := "cast_ability"
## 公开常量 `DASH`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const DASH := "dash"
## 公开常量 `INTERACT`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const INTERACT := "interact"
## 公开常量 `SELECT_REWARD`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const SELECT_REWARD := "select_reward"
## 公开常量 `OPEN_INVENTORY`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const OPEN_INVENTORY := "open_inventory"
## 公开常量 `CLOSE_INVENTORY`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const CLOSE_INVENTORY := "close_inventory"
## 公开常量 `EQUIP_ITEM`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const EQUIP_ITEM := "equip_item"
## 公开常量 `UNEQUIP_ITEM`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const UNEQUIP_ITEM := "unequip_item"
## 公开常量 `PAUSE`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const PAUSE := "pause"
## 公开常量 `RESUME`，作为 `BuiltinCommands` 对外暴露的类型、事件或命令标识。
const RESUME := "resume"
