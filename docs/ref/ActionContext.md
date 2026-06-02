# ActionContext

## 概念说明

ActionContext 是 Action 执行时携带的上下文，继承自 GameplayContext。在标准上下文字段之外，额外提供 action_id、duration、elapsed 和 phase 等 Action 生命周期相关数据。Action 应该复用在不同实体上，所以不能直接依赖某一个 Player 脚本。

## 设计目的

ActionContext 扩展 GameplayContext，让 Action 的执行过程有专属的时间和阶段字段。State 负责组装 Context，Action 只读 Context 执行时间过程，避免 Action 直接依赖具体 Player 输入或 UI。

## 文件

`res://addons/mkit/kernel/context/action_context.gd`

## 接口

```gdscript
class_name ActionContext
extends GameplayContext

var action_id: String = ""
var duration: float = 0.0
var elapsed: float = 0.0
var phase: String = ""

static func from_command(command: GameCommand, source_node: Node = null, target_node: Node = null) -> ActionContext
```

## 函数使用场景

- **from_command()**：从命令快速构造 ActionContext。例：BasicAttackState 收到攻击命令后，用命令的 payload 创建 ActionContext，传给 TimedAttackAction 执行。

## 使用示例

### 创建 ActionContext

```gdscript
var action_context := ActionContext.new()
action_context.source = player
action_context.target = enemy
action_context.direction = Vector2.RIGHT
action_context.duration = 0.25
action_context.payload["combo_index"] = 1
```

### 从命令创建

```gdscript
var ctx := ActionContext.from_command(command, owner_entity, target_enemy)
ctx.duration = 0.3
```
