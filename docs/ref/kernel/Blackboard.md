# Blackboard

**层：** Kernel  
**文件：** `addons/mkit/kernel/context/blackboard.gd`  
**继承：** `extends RefCounted`

## 职责

一个键值黑板，用于在 `StateMachine`、`State` 与 `Brain` 之间共享易变的运行时数据（如当前目标、移动方向、AI 意图）。`StateMachine` 持有一个，并在 `setup` 时注入到所有 `State`。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `set_value(key: String, value) -> void` | — | 写入 |
| `get_value(key: String, default_value = null)` | `Variant` | 读取，缺省返回 `default_value` |
| `has_value(key: String) -> bool` | `bool` | 是否存在 |
| `erase_value(key: String) -> void` | — | 删除一个键 |
| `clear() -> void` | — | 清空 |
| `to_debug_dict() -> Dictionary` | `Dictionary` | 复制一份用于调试打印 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# State 内部（blackboard 由 StateMachine 注入）
blackboard.set_value("target", enemy)
var t := blackboard.get_value("target", null) as Node

# Brain 内部（Brain 自带一个独立 blackboard）
blackboard.set_value("intent", "attack")
```

## 相关

- → [StateMachine](StateMachine.md)（持有并注入 blackboard）
- → [State](State.md)（通过 `blackboard` 访问）
- → [ref/modules/Brain.md](../modules/Brain.md)（AI 用 blackboard 存意图/目标）
