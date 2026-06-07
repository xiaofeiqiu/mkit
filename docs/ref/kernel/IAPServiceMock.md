# IAPServiceMock

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/iap_service_mock.gd`  
**继承：** `extends IAPService`  
**服务 ID：** `"iap"`（`GameBootstrap` 默认注册）

## 职责

默认内购适配器。模拟商品加载、购买、恢复购买，并在内存中记录已购买的 `product_id`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `_purchased` | `Array[String]` | `[]` | 已模拟购买的商品 ID |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `load_products(product_ids: Array[String]) -> void` | — | 0.1 秒后原样发 `products_loaded` |
| `purchase(product_id: String) -> void` | — | 0.3 秒后记录商品并发 `purchase_completed` |
| `restore_purchases() -> void` | — | 0.2 秒后发 `restore_completed(_purchased)` |
| `is_purchased(product_id: String) -> bool` | `bool` | 查询内存购买记录 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var iap: IAPService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_IAP) as IAPService
iap.purchase("premium_pack")
```

### 典型场景（Level 2）

```gdscript
func buy_no_ads() -> void:
    var iap: IAPService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_IAP) as IAPService
    if iap == null:
        return
    iap.purchase_completed.connect(func(product_id: String) -> void:
        if product_id == "no_ads":
            _unlock_no_ads()
    )
    iap.purchase("no_ads")
```

## 相关

- → [IAPService](IAPService.md) · [GameBootstrap](GameBootstrap.md)
