# ResourceSet

**文件：** `addons/mkit/modules/combat/resource_set.gd`  
**用途：** 通用资源计量容器（当前值 + 上限提供器），用于可序列化资源状态。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `current` | `Dictionary` | `{}` | 当前资源映射 |
| `max_value_provider` | `Callable` | `Callable()` | 查询上限函数 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `set_max_provider(value: Callable) -> void` | `void` | 设置上限提供器 |
| `get_current(resource_id: String) -> float` | `float` | 读取当前值（缺省为上限） |
| `get_max(resource_id: String) -> float` | `float` | 通过 `max_value_provider` 获取上限 |
| `has(resource_id: String, amount: float) -> bool` | `bool` | 检查是否有足够资源 |
| `set_current(resource_id: String, value: float) -> void` | `void` | 设置并夹紧到 `[0, max]` |
| `spend(resource_id: String, amount: float) -> bool` | `bool` | 扣减，失败返回 `false` |
| `restore(resource_id: String, amount: float) -> void` | `void` | 恢复资源 |
| `clear() -> void` | `void` | 清空当前值 |
| `to_save_data() -> Dictionary` | `Dictionary` | 导出保存数据 |
| `from_save_data(data: Dictionary) -> void` | `void` | 从保存数据恢复 |

## 相关

- → [ResourcePoolComponent](ResourcePoolComponent.md)
