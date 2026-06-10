# ProgressionService

**层：** Module  
**文件：** `addons/mkit/modules/progression/progression_service.gd`  
**继承：** `extends Saveable`  
**服务 ID：** `"progression"`

## 职责

全局货币与元升级（roguelite 的局外成长）。`add_currency`/`spend_currency` 管货币（商店、奖励都用它），`unlock_or_level_up` 花货币买永久升级并跑其 effects。是 `Saveable`（`save_id="progression"`），开箱即存。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `add_currency(currency_id, amount) -> void` | — | 加货币 |
| `spend_currency(currency_id, amount) -> bool` | `bool` | 扣货币，不够 false |
| `get_currency(currency_id) -> int` | `int` | 查货币 |
| `can_unlock(upgrade_id) -> bool` | `bool` | 是否可升级（前置/货币）|
| `unlock_or_level_up(upgrade_id, context := null) -> bool` | `bool` | 升一级并扣费、跑 effects |

## 信号

`currency_changed(currency_id, amount)` · `upgrade_level_changed(upgrade_id, level)` · `content_unlocked(content_id)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var prog := Mkit.progression()
prog.add_currency("gold", 100)
print(prog.get_currency("gold"))
```

### 典型场景（Level 2）

```gdscript
# 元升级商店：买得起就升，否则提示
func buy_upgrade(upgrade_id: String) -> void:
    var prog := Mkit.progression()
    prog.currency_changed.connect(func(id: String, amt: int): _refresh_currency_label(id, amt))
    if not prog.can_unlock(upgrade_id):
        print("无法升级（货币不足或已满级）")   # 失败路径
        return
    if prog.unlock_or_level_up(upgrade_id):       # 成功：扣费 + 跑 UpgradeDefinition.effects
        print("升级成功")
```

## 相关

- → [ProgressionState](ProgressionState.md) · [UpgradeDefinition](UpgradeDefinition.md) · [AddCurrencyEffect](AddCurrencyEffect.md) · [SpendCurrencyEffect](SpendCurrencyEffect.md)
- → [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md) · [cookbook/14_shop.md](../../cookbook/14_shop.md)
