# IAPService

## 概念说明

IAPService 的当前参考文档由实际代码声明补齐。该条目用于记录代码中已经存在但 docs/ref 原先缺失的类型。

## 设计目的

以当前实现为准，提供字段和公开接口索引，便于后续补充更详细的业务语义说明。

## 文件

`res://addons/mkit/kernel/services/iap_service.gd`
## 接口

```gdscript
class_name IAPService
extends Node
signal products_loaded(product_ids: Array)
signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(restored_ids: Array)
func load_products(product_ids: Array[String]) -> void
func purchase(product_id: String) -> void
func restore_purchases() -> void
func is_purchased(product_id: String) -> bool
```

