# GameBootstrap

**层：** Kernel  
**文件：** `addons/mkit/kernel/bootstrap/game_bootstrap.gd`  
**继承：** `extends Node`

## 职责

游戏启动入口。在 `_ready` 时注册 **kernel 内置服务**，加载内容数据库，把内容驱动的服务配置（如 `AudioDefinition`）注册到对应服务，校验内容、加载存档，最后切换到初始场景。

> kernel 层只注册 kernel 自己的服务。需要内置玩法模块（combat / quest / shop / dialogue / world / loot / progression）时用 [ModuleBootstrap](../modules/ModuleBootstrap.md)（组合根），或继承它再叠加自定义服务。

## 字段（@export 和 public var）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `resource_databases` | `Array[ResourceDatabase]` | `[]` | 要加载的内容数据库列表；`_load_content` 时遍历注册 |
| `initial_scene_path` | `String` | `""` | 启动完成后切入的场景路径（`res://` 或 `uid://`）；留空则不切换 |
| `save_path` | `String` | `""` | 可选存档路径；非空时启动自动读档前写入 `SaveService.save_path` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `boot() -> void` | `void` | 启动入口，按序调用下面步骤 |
| `_register_kernel_services() -> void` | `void` | 注册服务表；**override `_build_services()` 添加或替换服务** |
| `_build_services() -> Dictionary` | `Dictionary` | 有序 id → 服务实例表（仅 kernel 服务）；子类 override 后 `super()` 再追加 |
| `_load_content() -> void` | `void` | 遍历 `resource_databases`，调 `ContentService.load_database()` |
| `_configure_content_services() -> void` | `void` | 内容入库后配置内容驱动的服务 |
| `_register_audio_definitions() -> void` | `void` | 将 `ContentService` 中的 `AudioDefinition` 注册到 `AudioService` |
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
extends ModuleBootstrap   # 含内置模块服务；只要 kernel 服务则 extends GameBootstrap


func _build_services() -> Dictionary:
    var services := super()             # 先拿内置服务表

    # 添加自定义服务
    services["my_analytics"] = MyAnalyticsService.new()
    return services


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
- → [AudioDefinition](AudioDefinition.md)
- → [pipeline.md — Runtime Bootstrap](../../pipeline.md#1-runtime-bootstrap)
- → [cookbook/01_bootstrap.md](../../cookbook/01_bootstrap.md)
