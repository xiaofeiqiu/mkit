# ServiceRegistry

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/service_registry.gd`  
**继承：** `extends Node`（Autoload 单例）

## 职责

全局服务表。唯一的 Autoload，持有 id → 服务实例的映射。游戏/模块代码访问内置服务的推荐入口是类型化门面 [Mkit](../modules/Mkit.md)；`get_port` 是底层访问器，供 kernel 内部与自定义服务使用。

## 字段（public var）

无公开字段（内部 `_services: Dictionary` 存储映射）。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `register_service(id: String, service: Object, expected_class_name: String = "") -> void` | `void` | 注册服务；重复注册会替换并 warning；可选类型名校验 |
| `has_service(id: String) -> bool` | `bool` | 检查服务是否已注册 |
| `get_port(service_id: String, expected_class_name: String = "") -> Object` | `Object` | 底层访问器。缺失时 warning，可选类型名检查（支持 class_name 脚本类）|
| `get_port_ids() -> Array[String]` | `Array[String]` | 同 `get_registered_service_ids` |
| `get_service(id: String) -> Object` | `Object` | **已废弃**：改用 `Mkit` 门面或 `get_port` |
| `get_service_or_null(id: String) -> Object` | `Object` | 同 `get_service` 的无 warning 变体 |
| `unregister_service(id: String) -> void` | `void` | 从注册表中移除（测试清理用）|
| `clear() -> void` | `void` | 清空所有注册（仅测试用，**生产代码禁止调用**）|
| `get_registered_service_ids() -> Array[String]` | `Array[String]` | 返回服务表 ID（按字母排序）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var events := Mkit.events()
if events != null:
    events.emit_domain_event(DomainEvent.create("test", "", "", {}))
```

### 典型场景（Level 2）

```gdscript
# 安全取服务模式（在任何 Node._ready 中）
func _ready() -> void:
    var combat := Mkit.combat()
    if combat == null:
        push_error("CombatService not registered — is GameBootstrap running first?")
        return
    # ... 使用 combat（已是 CombatService 类型，无需再 cast）

# 自定义服务没有 Mkit 访问器，走底层 get_port：
var my_service := ServiceRegistry.get_port("my_service") as MyService
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

- 游戏/模块代码统一走 [Mkit](../modules/Mkit.md) 门面；kernel 内部与自定义服务用 `get_port`。
- `get_service` 已废弃（仅兼容旧脚本）；`get_service_or_null` 是无 warning 的存在性查询变体。
- `ui` 服务通常由场景里的 `UIManager` 自注册，不是 `GameBootstrap._build_services()` / `ModuleBootstrap` 的内置项。

## 相关

- → [Mkit](../modules/Mkit.md) — 类型化服务门面（推荐入口）
- → [GameBootstrap](GameBootstrap.md) — 在启动时批量注册服务
- → [pipeline.md — Runtime Bootstrap](../../pipeline.md#1-runtime-bootstrap)
- → [architecture.md — ServiceRegistry 模式](../../architecture.md#serviceregistry-模式)
