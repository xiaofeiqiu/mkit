# MkitRuntimeContext

**文件：** `addons/mkit/kernel/runtime/mkit_runtime_context.gd`  
**用途：** 提供 typed/字符串端口注册与查找的 runtime context（配合 `ServiceRegistry` 使用）。

## 字段

无公开字段（内部 `_ports: Dictionary` 存储端口映射）。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_port(service_id: String, service: Object, expected_class_name: String = "") -> void` | `void` | 注册端口；支持类型提示并输出 mismatch 警告 |
| `unregister_port(service_id: String) -> void` | `void` | 注销端口 |
| `has_port(service_id: String) -> bool` | `bool` | 端口是否存在 |
| `get_port(service_id: String) -> Object` | `Object` | 按 ID 读取端口 |
| `get_port_typed(service_id: String, expected_class_name: String) -> Object` | `Object` | 读取端口并进行类型兼容检查 |
| `get_registered_ports() -> Array[String]` | `Array[String]` | 获取已注册端口 ID（排序） |

## 说明

`ServiceRegistry.set_runtime_context()` 注入后，`ServiceRegistry.get_port()` 会走 `MkitRuntimeContext`，实现 typed 访问路径。

## 典型用法

```gdscript
var runtime_ctx := ServiceRegistry.get_runtime_context()
if runtime_ctx != null:
    var ids := runtime_ctx.get_registered_ports()
    print(ids)
```

## 相关

- → [ServiceRegistry](ServiceRegistry.md)
