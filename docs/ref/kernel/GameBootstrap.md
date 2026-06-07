# GameBootstrap

**层：** Kernel  
**文件：** `addons/mkit/kernel/bootstrap/game_bootstrap.gd`  
**继承：** `extends Node`

## 职责

游戏启动入口。在 `_ready` 时依次注册所有内置服务、加载内容数据库、校验内容、加载存档，最后切换到初始场景。

## 字段（@export 和 public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `resource_databases` | `Array[ResourceDatabase]` | `[]` | 要加载的内容数据库列表；`_load_content` 时遍历注册 |
| `initial_scene_path` | `String` | `""` | 启动完成后切入的场景路径（`res://` 或 `uid://`）；留空则不切换 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `boot() -> void` | `void` | 启动入口，按序调用下面四个私有步骤 |
| `_register_kernel_services() -> void` | `void` | 注册所有内置服务；**override 此方法添加自定义服务** |
| `_load_content() -> void` | `void` | 遍历 `resource_databases`，调 `ContentService.load_database()` |
| `_validate_content() -> void` | `void` | 调 `ContentService.validate_all()`；失败时 `push_error` |
| `_load_profile() -> void` | `void` | 若存档文件存在，调 `SaveService.load_game(tree.root)` |
| `_enter_initial_scene() -> void` | `void` | `call_deferred` 后调用，切换到 `initial_scene_path` 场景 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在场景根节点直接使用 GameBootstrap（Inspector 配置）
# 无需代码，Inspector 设好 resource_databases 和 initial_scene_path 即可
```

### 典型场景（Level 2）

```gdscript
# res://game/bootstrap/my_bootstrap.gd
class_name MyBootstrap
extends GameBootstrap


func _register_kernel_services() -> void:
    super._register_kernel_services()   # 先注册所有内置服务

    # 添加自定义服务
    var my_svc := MyAnalyticsService.new()
    ServiceRegistry.register_service("my_analytics", my_svc)

    # 验证注册结果
    if not ServiceRegistry.has_service("my_analytics"):
        push_error("MyBootstrap: my_analytics failed to register")


func _load_profile() -> void:
    super._load_profile()               # 调用默认存档加载

    # 加载后做额外初始化（如从存档恢复游戏状态）
    var save_svc := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
    if save_svc != null:
        print("Save loaded from: %s" % save_svc.save_path)
```

## 相关

- → [ServiceRegistry](ServiceRegistry.md)
- → [ResourceDatabase](ResourceDatabase.md)
- → [ContentService](ContentService.md)
- → [pipeline.md — Runtime Bootstrap](../../pipeline.md#1-runtime-bootstrap)
- → [cookbook/01_bootstrap.md](../../cookbook/01_bootstrap.md)
