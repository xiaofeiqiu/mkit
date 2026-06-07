# Wallet

**文件：** `addons/mkit/modules/progression/wallet.gd`  
**用途：** 货币钱包模型，`ProgressionState` 用于运行时余额读写与保存序列化。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `balances` | `Dictionary` | `{}` | 货币余额映射 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_balance(currency_id: String) -> int` | `int` | 读取余额 |
| `set_balance(currency_id: String, amount: int) -> void` | `void` | 设置（不允许小于 0） |
| `add(currency_id: String, amount: int) -> void` | `void` | 增加金额 |
| `can_spend(currency_id: String, amount: int) -> bool` | `bool` | 是否可扣 |
| `spend(currency_id: String, amount: int) -> bool` | `bool` | 扣款，失败返回 `false` |
| `to_save_data() -> Dictionary` | `Dictionary` | 导出余额 |
| `from_save_data(data: Dictionary) -> void` | `void` | 从字典恢复 |

## 相关

- → [ProgressionState](ProgressionState.md)
- → [ProgressionService](ProgressionService.md)
