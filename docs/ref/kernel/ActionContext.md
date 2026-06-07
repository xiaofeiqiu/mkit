# ActionContext

**层：** Kernel  
**文件：** `addons/mkit/kernel/context/action_context.gd`  
**继承：** `extends GameplayContext`

## 职责

`GameplayContext` 的子类，给带时序的 `GameAction` 多带几个运行时字段（`action_id` / `duration` / `elapsed` / `phase`）。`GameAction.context` 的类型就是它。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `action_id` | `String` | `""` | 当前动作标识 |
| `duration` | `float` | `0.0` | 动作总时长（由动作写入，如 `CastAction.duration`）|
| `elapsed` | `float` | `0.0` | 已过时间（动作 `_on_update` 中同步 `elapsed`）|
| `phase` | `String` | `""` | 阶段标记（startup/active/recovery 等，按需自填）|

> 继承自 `GameplayContext` 的字段（`source` / `target` / `direction` / `payload` …）同样可用，见 [GameplayContext](GameplayContext.md)。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static from_command(command, source_node, target_node)` | `ActionContext` | 从命令构造（同 `GameplayContext.from_command`，返回 ActionContext）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var ctx := ActionContext.new()
ctx.source = player
ctx.target = enemy
var action := TimedAttackAction.new()
var runner := ServiceRegistry.get_port(ServiceRegistry.SERVICE_ACTIONS) as ActionService
runner.start_action(action, ctx)
```

## 相关

- → [GameplayContext](GameplayContext.md)（基类，共享信使）
- → [GameAction](GameAction.md)（持有 `context: ActionContext`）
- → [ActionService](ActionService.md)
