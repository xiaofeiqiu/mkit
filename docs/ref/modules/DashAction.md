# DashAction

**层：** Module  
**文件：** `addons/mkit/modules/combat/actions/dash_action.gd`  
**继承：** `extends GameAction`

## 职责

冲刺动作：在 `duration` 内以 `speed` 沿 `context.direction` 推动 `CharacterBody2D`，结束清零速度。可被 `stun` / `death` 打断。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `duration` | `float` | `0.18` | 冲刺时长 |
| `speed` | `float` | `480.0` | 冲刺速度 |
| `direction` | `Vector2` | `Vector2.ZERO` | 方向（`_on_start` 时从 `context.direction` 取，零则取 RIGHT）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var dash := DashAction.new()
var ctx := ActionContext.new()
ctx.source = player           # CharacterBody2D
ctx.direction = Vector2.RIGHT
(ServiceRegistry.get_port(ServiceRegistry.SERVICE_ACTIONS) as ActionService).start_action(dash, ctx)
```

## 相关

- → [GameAction](../kernel/GameAction.md) · [ActionService](../kernel/ActionService.md)
