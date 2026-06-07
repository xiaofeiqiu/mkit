# SpendCurrencyEffect

**层：** Module  
**文件：** `addons/mkit/modules/progression/spend_currency_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果：从 `ProgressionService` 扣货币，不够则失败。`ShopService` 购买结算用它。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `currency_id` | `String` | `""` | 货币 id（普通 `var`，**非 @export**）|
| `amount` | `int` | `0` | 数量 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `static can_spend(currency_id, amount) -> bool` | `bool` | 预检查是否够 |
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 扣款；不够返回 `Insufficient currency` |

## 使用模式

### 最小示例（Level 1）

```gdscript
if SpendCurrencyEffect.can_spend("gold", 50):
    var spend := SpendCurrencyEffect.new()
    spend.currency_id = "gold"
    spend.amount = 50
    (ServiceRegistry.get_service("effects") as EffectService).execute(spend, GameplayContext.new())
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [AddCurrencyEffect](AddCurrencyEffect.md) · [ProgressionService](ProgressionService.md) · [ShopService](ShopService.md)
