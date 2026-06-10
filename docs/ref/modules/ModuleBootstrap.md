# ModuleBootstrap

**层：** Modules  
**文件：** `addons/mkit/modules/module_bootstrap.gd`  
**继承：** `extends GameBootstrap`

## 职责

内置玩法模块的**组合根（composition root）**。`GameBootstrap` 只注册 kernel 服务；本类 override `_build_services()` 追加 7 个模块服务：`combat`、`progression`、`quest`、`shop`、`dialogue`、`world`、`loot`。使用内置模块的游戏（含 `game/bootstrap.tscn` 模板）应通过它（或其子类）启动。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_build_services() -> Dictionary` | `Dictionary` | `super()` 取 kernel 服务表后追加模块服务 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# bootstrap.tscn 根节点挂 module_bootstrap.gd，Inspector 配置
# resource_databases 与 initial_scene_path 即可
```

### 典型场景（Level 2）

```gdscript
# 只用部分模块或追加自定义服务：继承后改表
class_name MyBootstrap
extends ModuleBootstrap


func _build_services() -> Dictionary:
    var services := super()
    services.erase(ServiceRegistry.SERVICE_SHOP)   # 裁掉不用的模块
    services["my_service"] = MyService.new()        # 追加自己的服务
    return services
```

## 相关

- → [GameBootstrap](../kernel/GameBootstrap.md) — kernel 启动流程与服务注册机制
- → [ServiceRegistry](../kernel/ServiceRegistry.md)
