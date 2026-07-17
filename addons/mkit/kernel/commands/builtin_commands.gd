class_name BuiltinCommands
extends Object
## 说明：`BuiltinCommands` 是 命令路由 的内置命令目录，负责集中定义常用 GameCommand 类型常量。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在命令路由中复用这段契约或状态时使用它。
## 示例：`var instance := BuiltinCommands.new()`

## 稳定标识 `MOVE`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const MOVE := "move"
## 稳定标识 `STOP_MOVE`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const STOP_MOVE := "stop_move"
## 稳定标识 `ATTACK`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ATTACK := "attack"
## 稳定标识 `CAST_ABILITY`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const CAST_ABILITY := "cast_ability"
## 稳定标识 `DASH`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const DASH := "dash"
## 稳定标识 `INTERACT`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const INTERACT := "interact"
## 稳定标识 `SELECT_REWARD`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const SELECT_REWARD := "select_reward"
## 稳定标识 `OPEN_INVENTORY`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const OPEN_INVENTORY := "open_inventory"
## 稳定标识 `CLOSE_INVENTORY`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const CLOSE_INVENTORY := "close_inventory"
## 稳定标识 `EQUIP_ITEM`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const EQUIP_ITEM := "equip_item"
## 稳定标识 `UNEQUIP_ITEM`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const UNEQUIP_ITEM := "unequip_item"
## 稳定标识 `PAUSE`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const PAUSE := "pause"
## 稳定标识 `RESUME`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const RESUME := "resume"
