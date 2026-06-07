# CloudSaveServiceMock

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/cloud_save_service_mock.gd`  
**继承：** `extends CloudSaveService`  
**服务 ID：** `"cloud_save"`（`GameBootstrap` 默认注册）

## 职责

内存版云存档适配器。按 slot 保存 `Dictionary` 副本，适合本地验证云存档调用路径；进程结束后数据不会持久化。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `_slots` | `Dictionary` | `{}` | slot → 存档数据副本 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `is_available() -> bool` | `bool` | 总是返回 `true` |
| `save_to_cloud(slot: String, data: Dictionary) -> void` | — | 写入内存 slot，0.2 秒后发 `cloud_save_completed` |
| `load_from_cloud(slot: String) -> void` | — | slot 存在则发 `cloud_load_completed`，否则发 `cloud_load_failed(slot, "no_data")` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var cloud: CloudSaveService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_CLOUD_SAVE) as CloudSaveService
cloud.save_to_cloud("slot_1", {"gold": 10})
```

### 典型场景（Level 2）

```gdscript
func sync_profile(data: Dictionary) -> void:
    var cloud: CloudSaveService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_CLOUD_SAVE) as CloudSaveService
    if cloud == null or not cloud.is_available():
        return
    cloud.cloud_load_failed.connect(func(slot: String, reason: String) -> void:
        push_warning("Cloud load failed: %s %s" % [slot, reason])
    )
    cloud.save_to_cloud("profile", data)
```

## 相关

- → [CloudSaveService](CloudSaveService.md) · [SaveService](SaveService.md)
