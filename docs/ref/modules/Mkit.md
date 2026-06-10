# Mkit

**层：** Modules  
**文件：** `addons/mkit/modules/mkit.gd`  
**继承：** `extends RefCounted`

## 职责

**类型化服务门面**——游戏代码与模块代码访问内置服务的唯一推荐入口。每个内置服务对应一个静态访问器，返回具体服务类型（缺失时返回 null 并 warning），调用方因此获得编辑器补全与类型检查，无需 `ServiceRegistry.get_port(...) as XxxService` 三段式样板。

因为它引用模块服务类型，所以放在 modules 层；kernel 内部代码仍直接用 `ServiceRegistry.get_port`（kernel 不允许反向依赖 modules）。

## 方法

全部为静态方法，无参数；按服务分组：

| 访问器 | 返回类型 |
|--------|----------|
| `events()` | `EventService` |
| `content()` | `ContentService` |
| `random()` | `RandomService` |
| `time()` | `TimeService` |
| `actions()` | `ActionService` |
| `effects()` | `EffectService` |
| `commands()` | `CommandService` |
| `scenes()` | `SceneService` |
| `pool()` | `PoolService` |
| `save()` | `SaveService` |
| `audio()` | `AudioService` |
| `analytics()` | `AnalyticsService` |
| `ads()` | `AdService` |
| `iap()` | `IAPService` |
| `cloud_save()` | `CloudSaveService` |
| `combat()` | `CombatService` |
| `progression()` | `ProgressionService` |
| `quest()` | `QuestService` |
| `shop()` | `ShopService` |
| `dialogue()` | `DialogueService` |
| `world()` | `WorldService` |
| `loot()` | `LootService` |
| `ui()` | `UIManager` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var result := Mkit.combat().resolve(req)
Mkit.events().emit_event("boss_defeated", boss_id)
```

### 典型场景（Level 2）

```gdscript
# 服务可能未注册（如裁剪了模块）时先判空
var shop := Mkit.shop()
if shop == null:
    return
shop.purchase(entry_id, buyer)
```

## 注意事项

- 自定义服务（不在内置表里的）仍走 `ServiceRegistry.get_port("my_service")`，或在自己的门面类里仿照本类加访问器。
- `ServiceRegistry.get_service` 已废弃，仅为旧代码兼容保留。

## 相关

- → [ServiceRegistry](../kernel/ServiceRegistry.md) — 底层注册与查找机制
- → [ModuleBootstrap](ModuleBootstrap.md) — 内置服务由谁注册
