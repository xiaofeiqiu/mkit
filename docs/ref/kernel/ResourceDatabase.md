# ResourceDatabase

**层：** Kernel  
**文件：** `addons/mkit/kernel/registry/resource_database.gd`  
**继承：** `extends Resource`

## 职责

内容资源的批量容器。在编辑器中配置，挂到 `GameBootstrap.resource_databases`，Bootstrap 启动时调 `get_all_resources()` 交给 `ContentService` 批量注册。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `database_id` | `String` | `""` | 数据库标识（人类可读，不参与查询）|
| `resources` | `Array[Resource]` | `[]` | 直接引用的资源数组（拖入编辑器 Inspector）|
| `resource_paths` | `Array[String]` | `[]` | 路径引用（`res://...`），懒加载 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_all_resources() -> Array[Resource]` | `Array[Resource]` | 合并 `resources` 和从 `resource_paths` 加载的资源 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 在 Inspector 中配置，无需代码
# GameBootstrap.resource_databases = [res://data/main_database.tres]
```

### 典型场景（Level 2）

```gdscript
# 分模块管理：多个 DB 挂到同一个 Bootstrap
# combat_database.tres   → 武器、技能、状态效果
# quest_database.tres    → 任务定义
# item_database.tres     → 物品、装备

# GameBootstrap.resource_databases = [
#     combat_database,
#     quest_database,
#     item_database,
# ]

# 运行时动态添加内容（如 DLC）
func _load_dlc_content(dlc_db_path: String) -> void:
    var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
    if content == null:
        return
    var db := ResourceLoader.load(dlc_db_path) as ResourceDatabase
    if db == null:
        push_error("DLC database not found: %s" % dlc_db_path)
        return
    content.load_database(db)
    var validation := content.validate_all()
    if not validation.success:
        push_error("DLC content validation failed: %s" % validation.errors)
```

**分组建议：**

| 数据库文件 | 存放内容 |
|-----------|----------|
| `data/combat_db.tres` | AbilityDefinition、StatusEffectDefinition |
| `data/item_db.tres` | ItemDefinition、LootTableDefinition |
| `data/quest_db.tres` | QuestDefinition |
| `data/world_db.tres` | RoomDefinition、ZoneDefinition |
| `data/audio_db.tres` | AudioDefinition |

## 相关

- → [ContentService](ContentService.md) — 调用 `load_database`
- → [ContentDefinition](ContentDefinition.md) — resources 数组中的元素类型
- → [GameBootstrap](GameBootstrap.md) — `resource_databases` export 字段
- → [concepts.md — 模型 3](../../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)
- → [cookbook/01_bootstrap.md](../../cookbook/01_bootstrap.md)
