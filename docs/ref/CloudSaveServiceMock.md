# CloudSaveServiceMock

## 概念说明

CloudSaveServiceMock 的当前参考文档由实际代码声明补齐。该条目用于记录代码中已经存在但 docs/ref 原先缺失的类型。

## 设计目的

以当前实现为准，提供字段和公开接口索引，便于后续补充更详细的业务语义说明。

## 文件

`res://addons/mkit/kernel/services/cloud_save_service_mock.gd`
## 接口

```gdscript
class_name CloudSaveServiceMock
extends CloudSaveService
func is_available() -> bool
func save_to_cloud(slot: String, data: Dictionary) -> void
func load_from_cloud(slot: String) -> void
```

