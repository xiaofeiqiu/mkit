# IAPService

**层：** Kernel（平台适配层）  
**文件：** `addons/mkit/kernel/services/iap_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"iap"`（默认注册 `IAPServiceMock`）

## 职责

内购的平台适配抽象。基类"未实现"；`GameBootstrap` 默认注册 `IAPServiceMock`。接 App Store / Google Play 时继承实现并替换。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `load_products(product_ids: Array[String]) -> void` | — | 拉取商品信息 |
| `purchase(product_id: String) -> void` | — | 发起购买 |
| `restore_purchases() -> void` | — | 恢复购买 |
| `is_purchased(product_id: String) -> bool` | `bool` | 是否已购 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `products_loaded` | `product_ids` | 商品加载完成 |
| `purchase_completed` | `product_id` | 购买成功 |
| `purchase_failed` | `product_id, reason` | 购买失败 |
| `restore_completed` | `restored_ids` | 恢复完成 |

## IAPServiceMock

**文件：** `addons/mkit/kernel/services/iap_service_mock.gd` · `extends IAPService`  
开发期默认实现：模拟延迟后总是"购买成功"，内部记录已购列表，`restore_purchases` 回放之。

## 使用模式

### 最小示例（Level 1）

```gdscript
var iap := ServiceRegistry.get_service("iap") as IAPService
iap.purchase_completed.connect(func(id: String): unlock_premium(id))
iap.purchase("remove_ads")
```

## 相关

- → [GameBootstrap](GameBootstrap.md)（替换点）· [AdService](AdService.md) · [CloudSaveService](CloudSaveService.md)
