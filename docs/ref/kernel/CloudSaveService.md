# CloudSaveService

**层：** Kernel（平台适配层）  
**文件：** `addons/mkit/kernel/services/cloud_save_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"cloud_save"`（默认注册 `CloudSaveServiceMock`）

## 职责

云存档的平台适配抽象。基类"未实现"；`GameBootstrap` 默认注册 `CloudSaveServiceMock`（内存槽位）。接 Steam Cloud / iCloud / Play Games 时继承实现并替换。本地存档仍由 [SaveService](SaveService.md) 负责，这层只管上云同步。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `is_available() -> bool` | `bool` | 云服务是否可用 |
| `save_to_cloud(slot: String, data: Dictionary) -> void` | — | 上传槽位数据 |
| `load_from_cloud(slot: String) -> void` | — | 下载槽位数据 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `cloud_save_completed` | `slot` | 上传成功 |
| `cloud_save_failed` | `slot, reason` | 上传失败 |
| `cloud_load_completed` | `slot, data` | 下载成功（带数据）|
| `cloud_load_failed` | `slot, reason` | 下载失败 |

## CloudSaveServiceMock

**文件：** `addons/mkit/kernel/services/cloud_save_service_mock.gd` · `extends CloudSaveService`  
开发期默认实现：`is_available` 恒 `true`，槽位存内存字典，模拟延迟后回调。

## 使用模式

### 最小示例（Level 1）

```gdscript
var cloud := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CLOUD_SAVE) as CloudSaveService
cloud.cloud_load_completed.connect(func(slot: String, data: Dictionary): apply_cloud_save(data))
if cloud.is_available():
    cloud.load_from_cloud("auto")
```

## 相关

- → [SaveService](SaveService.md)（本地存档）· [GameBootstrap](GameBootstrap.md)（替换点）
