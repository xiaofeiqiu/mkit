# ProgressionState

**层：** Module  
**文件：** `addons/mkit/modules/progression/progression_state.gd`  
**继承：** `extends RefCounted`

## 职责

全局进度的**纯数据**：货币钱包、元升级等级、已解锁内容。`ProgressionService.state` 持有它并负责存档。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `wallet` | `Wallet` | `Wallet.new()` | `currency_id → 数量` 的货币模型 |
| `upgrade_levels` | `Dictionary` | `{}` | `upgrade_id → 等级` |
| `unlocked_content_ids` | `Array[String]` | `[]` | 已解锁内容 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_currency(id) -> int` / `add_currency(id, amount)` / `spend_currency(id, amount) -> bool` | — | 货币读写 |
| `get_upgrade_level(id) -> int` / `set_upgrade_level(id, level)` | — | 升级等级 |
| `unlock_content(id) -> void` | — | 解锁内容 |
| `to_save_data()` / `from_save_data(data)` | — | 序列化 |

## 相关

- → [Wallet](Wallet.md) · [ProgressionService](ProgressionService.md)
