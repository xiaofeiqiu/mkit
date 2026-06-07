# AddCurrencyEffect

**层：** Module  
**文件：** `addons/mkit/modules/progression/add_currency_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果：给 `ProgressionService` 加货币。用作奖励、出售返还。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `currency_id` | `String` | `""` | 货币 id（普通 `var`，**非 @export**）|
| `amount` | `int` | `0` | 数量 |

> 字段不是 `@export`，无法在 Inspector 里填——需在代码里构造（`ShopService` 等内部使用）。要在编辑器配奖励，优先用带 `@export` 的 effect 或直接调 `ProgressionService.add_currency`。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 调 `ProgressionService.add_currency`，总是成功 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var add := AddCurrencyEffect.new()
add.currency_id = "gold"
add.amount = 25
(ServiceRegistry.get_service("effects") as EffectService).execute(add, GameplayContext.new())
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [SpendCurrencyEffect](SpendCurrencyEffect.md) · [ProgressionService](ProgressionService.md)
