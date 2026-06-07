# ContentService

**层：** Kernel  
**文件：** `addons/mkit/kernel/registry/content_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"content"`

## 职责

内容注册与查询中心。在 Bootstrap 时从 `ResourceDatabase` 批量加载所有 `ContentDefinition`，运行时按 ID 快速查询，启动时校验 ID 唯一性。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `load_database(database: ResourceDatabase) -> void` | `void` | 遍历 DB 中所有资源并注册 |
| `register_resource(res: Resource) -> void` | `void` | 注册单个 ContentDefinition；ID 重复时 `push_error` |
| `get_resource(content_id: String) -> Resource` | `Resource` | 按 ID 查询；不存在时 `push_warning` 并返回 null |
| `get_typed_resource(content_id, expected_script) -> Resource` | `Resource` | 同上，附带脚本类型检查 |
| `get_all_by_type(type_name: String) -> Array` | `Array` | 查询某类型的所有已注册资源 |
| `has(content_id: String) -> bool` | `bool` | 检查 ID 是否已注册（不产生 warning）|
| `validate_all() -> ContentValidationResult` | `ContentValidationResult` | 检查所有资源 ID 非空；Bootstrap 自动调用 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
var def := content.get_resource("fireball") as AbilityDefinition
if def == null:
    push_error("fireball not registered")
```

### 典型场景（Level 2）

```gdscript
# 在 AbilityController 中查询并缓存 definition
func get_definition(ability_id: String) -> AbilityDefinition:
    if ability_id.strip_edges() == "":
        return null
    var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
    if content == null:
        push_error("ContentService not available")
        return null

    # 推荐：先用 has() 检查，避免产生无意义 warning
    if not content.has(ability_id):
        push_warning("AbilityDefinition not found: %s" % ability_id)
        return null

    return content.get_resource(ability_id) as AbilityDefinition


# 列出所有已注册的 ItemDefinition（如商店列表）
func get_all_items() -> Array[ItemDefinition]:
    var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
    if content == null:
        return []
    var raw := content.get_all_by_type("item_definition")
    var result: Array[ItemDefinition] = []
    for r in raw:
        var item := r as ItemDefinition
        if item != null:
            result.append(item)
    return result


# 启动时手动注册一个运行时生成的资源
func _register_dynamic_content() -> void:
    var content := ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
    if content == null:
        return
    var def := QuestDefinition.new()
    def.quest_id = "dynamic_quest_001"
    def.display_name = "Dynamic Quest"
    content.register_resource(def)
```

## 相关

- → [ContentDefinition](ContentDefinition.md) — 所有内容资源的基类
- → [ResourceDatabase](ResourceDatabase.md) — 批量存放 ContentDefinition 的容器
- → [ContentValidationResult](ContentValidationResult.md) — validate_all 的返回值
- → [GameBootstrap](GameBootstrap.md) — `_load_content` 调用 load_database
- → [concepts.md — 模型 3：内容注册与查询](../../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)
- → [cookbook/05_ability.md](../../cookbook/05_ability.md)
