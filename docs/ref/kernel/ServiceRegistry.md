# ServiceRegistry

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/service_registry.gd`  
**继承：** `extends Node`（Autoload 单例）

## 职责

全局服务入口。唯一的 Autoload，持有兼容服务表，并在存在 `MkitRuntimeContext` 时把服务同步注册为 runtime ports。新代码通过 `get_port(ServiceRegistry.SERVICE_*)` 访问服务。

## 字段（public var）

无公开字段（内部 `_services: Dictionary` 存储映射）。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_service(id: String, service: Object, class_name: String = "") -> void` | `void` | 注册服务；重复注册会替换并 warning；runtime context 存在时同步注册 port |
| `has_service(id: String) -> bool` | `bool` | 检查服务是否已注册 |
| `get_port(service_id: String, expected_class_name: String = "") -> Object` | `Object` | 优先入口。若 runtime_context 未就绪，退化为 `get_service_or_null` |
| `get_port_ids() -> Array[String]` | `Array[String]` | 优先入口（从 runtime_context 读） |
| `get_service(id: String) -> Object` | `Object` | 获取服务，不存在时返回 null 并 warning |
| `get_service_or_null(id: String) -> Object` | `Object` | 同 `get_service` 的无 warning 变体 |
| `get_typed(id: String, class_name: String) -> Object` | `Object` | 同 get_service，附带类型名检查 |
| `unregister_service(id: String) -> void` | `void` | 从注册表中移除（测试清理用）|
| `clear() -> void` | `void` | 清空所有注册（仅测试用，**生产代码禁止调用**）|
| `set_runtime_context(runtime_context: MkitRuntimeContext) -> void` | `void` | 注入当前 runtime context |
| `get_runtime_context() -> MkitRuntimeContext` | `MkitRuntimeContext` | 读取当前 runtime context |
| `get_registered_service_ids() -> Array[String]` | `Array[String]` | 返回兼容服务表 ID（按字母排序）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var events := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService
if events != null:
    events.emit_domain_event(DomainEvent.create("test", "", "", {}))
```

### 典型场景（Level 2）

```gdscript
# 安全取服务模式（在任何 Node._ready 中）
func _ready() -> void:
    var combat := ServiceRegistry.get_port(ServiceRegistry.SERVICE_COMBAT)
    if combat == null:
        push_error("CombatService not registered — is GameBootstrap running first?")
        return
    var combat_typed := combat as CombatService
    # ... 使用 combat
```

```gdscript
# 测试环境：注册 Mock 替代真实服务
func _setup_test_registry() -> void:
    ServiceRegistry.clear()             # 清空（仅测试用）
    ServiceRegistry.register_service("events", EventService.new())
    ServiceRegistry.register_service("effects", EffectService.new())
    # 注意：clear() 不移除 GameBootstrap 添加为子节点的服务节点
    # 需要先 remove_child 再 clear，参见集成测试陷阱文档
```

## 说明

- 新代码统一采用 `get_port(ServiceRegistry.SERVICE_*)`。
- `get_service` / `get_service_or_null` / `get_typed` 保留历史兼容脚本，不作为默认入口。
- `ui` 服务通常由场景里的 `UIManager` 自注册，不是 `GameBootstrap._build_kernel_services()` 的内置项。

## 相关

- → [GameBootstrap](GameBootstrap.md) — 在启动时批量注册服务
- → [pipeline.md — Runtime Bootstrap](../../pipeline.md#1-runtime-bootstrap)
- → [architecture.md — ServiceRegistry 模式](../../architecture.md#serviceregistry-模式)
