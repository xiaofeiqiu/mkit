# Content Registry

---

# 3. Content Registry 接口设计

---

## 3.1 ResourceDatabase

### 概念说明

- 是什么：一组内容资源的数据库 Resource。
- 负责什么：把物品、技能、敌人、房间、奖励、状态等资源批量交给 ContentRegistry 加载。
- 为什么需要：大型 RPG/roguelike 内容很多，手动在代码里逐个注册资源不可维护。

### 文件

`res://addons/mkit/kernel/registry/resource_database.gd`

```gdscript
class_name ResourceDatabase
extends Resource

@export var database_id: String = ""
@export var resources: Array[Resource] = []
@export var resource_paths: Array[String] = []

func get_all_resources() -> Array[Resource]:
    var result: Array[Resource] = []
    result.append_array(resources)

    for path in resource_paths:
        var res := load(path)
        if res != null:
            result.append(res)
        else:
            push_warning("Failed to load resource: %s" % path)

    return result
```

#### 字段说明
- **database_id**：稳定 ID 字段。例：ResourceDatabase 通过 database_id 引用某个定义或运行时对象，避免直接保存节点路径。
#### 函数使用场景
- **get_all_resources()**：读取数据入口。实际例子：CombatResolver 通过 get_all_resources 获取最终攻击力，而不是直接读内部变量。

---

### 27.11 ResourceDatabase 使用示例

#### 详细实际用例

- 真实场景：你创建 `items_database.tres`、`abilities_database.tres`、`rooms_database.tres`，每个数据库里拖入一组 Resource。Bootstrap 启动时批量加载这些数据库。
- 怎么使用：按内容域拆数据库，方便编辑器维护和版本管理。不要在代码里手写一长串 `load("res://...")`。
- 验证重点：数据库里每个资源都能被 ContentRegistry 读出 content id；重复 ID 会在启动校验时报错。
### 创建 Item Database Resource

```gdscript
var db := ResourceDatabase.new()
db.database_id = "items.core"
db.resources = [
    preload("res://game/content/items/sword_iron.tres"),
    preload("res://game/content/items/potion_small.tres")
]
```

### 在 GameBootstrap 中加载

```gdscript
@export var resource_databases: Array[ResourceDatabase] = [
    preload("res://game/content/items/item_database.tres"),
    preload("res://game/content/abilities/ability_database.tres")
]
```

---

---

---

## 3.2 ContentRegistry

### 概念说明

- 是什么：稳定内容 ID 到 Resource 定义的查找表。
- 负责什么：加载数据库、检查重复 ID、检查缺失引用，并提供按 ID 查找能力。
- 为什么需要：存档、掉落表、技能和奖励都应该保存稳定 ID，而不是脆弱的场景路径或节点引用。

### 文件

`res://addons/mkit/kernel/registry/content_registry.gd`

### 统一 Content 接口约定

所有可注册 Resource 都需要有稳定 ID 字段，例如：

```gdscript
var item_id: String
var ability_id: String
var status_id: String
var room_id: String
var upgrade_id: String
var entity_definition_id: String
```

### 接口

```gdscript
class_name ContentRegistry
extends Node

var _by_id: Dictionary = {}
var _by_type: Dictionary = {}
var _resource_path_by_id: Dictionary = {}

func load_database(database: ResourceDatabase) -> void:
    for res in database.get_all_resources():
        register_resource(res)

func register_resource(res: Resource) -> void:
    var content_id := _extract_content_id(res)
    if content_id == "":
        push_error("Resource missing stable content id: %s" % res)
        return

    if _by_id.has(content_id):
        push_error("Duplicate content id: %s" % content_id)
        return

    _by_id[content_id] = res

    var type_name := _get_resource_type_name(res)
    if not _by_type.has(type_name):
        _by_type[type_name] = []
    _by_type[type_name].append(res)

    if res.resource_path != "":
        _resource_path_by_id[content_id] = res.resource_path

func get_resource(content_id: String) -> Resource:
    if not _by_id.has(content_id):
        push_warning("Content id not found: %s" % content_id)
        return null
    return _by_id[content_id]

func get_typed_resource(content_id: String, expected_script: Script) -> Resource:
    var res := get_resource(content_id)
    if res == null:
        return null
    if expected_script != null and res.get_script() != expected_script:
        # Godot script inheritance check can be added later.
        pass
    return res

func get_all_by_type(type_name: String) -> Array:
    if not _by_type.has(type_name):
        return []
    return _by_type[type_name]

func has(content_id: String) -> bool:
    return _by_id.has(content_id)

func validate_all() -> ContentValidationResult:
    var result := ContentValidationResult.new()
    result.success = true

    for id in _by_id.keys():
        var res := _by_id[id]
        if id == "":
            result.add_error("Empty content id")
        if res == null:
            result.add_error("Null resource for id %s" % id)

    return result

func _extract_content_id(res: Resource) -> String:
    if res == null:
        return ""
    for property_name in ["item_id", "ability_id", "status_id", "room_id", "upgrade_id", "entity_definition_id", "enemy_id", "loot_table_id", "reward_id", "stat_id"]:
        if property_name in res:
            return str(res.get(property_name))
    return ""

func _get_resource_type_name(res: Resource) -> String:
    if res == null:
        return "Unknown"
    var script := res.get_script()
    if script != null and script.resource_path != "":
        return script.resource_path.get_file().get_basename()
    return res.get_class()
```

#### 函数使用场景
- **load_database()**：加载流程。实际例子：ContentRegistry.load_database 把所有 item/ability/room 资源注册进表。
- **register_resource()**：注册入口。实际例子：GameBootstrap 启动时把 EventRouter 注册为 events 服务。
- **get_resource()**：读取数据入口。实际例子：CombatResolver 通过 get_resource 获取最终攻击力，而不是直接读内部变量。
- **get_typed_resource()**：读取数据入口。实际例子：CombatResolver 通过 get_typed_resource 获取最终攻击力，而不是直接读内部变量。
- **get_all_by_type()**：读取数据入口。实际例子：CombatResolver 通过 get_all_by_type 获取最终攻击力，而不是直接读内部变量。
- **has()**：公开 API。实际例子：外部系统通过它请求 **ContentRegistry** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **validate_all()**：校验流程。实际例子：启动时检查是否有重复 item_id 或奖励引用了不存在的 effect。
- **_extract_content_id()**：内部辅助函数。实际例子：由 **ContentRegistry** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_get_resource_type_name()**：内部辅助函数。实际例子：由 **ContentRegistry** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

### ContentValidationResult

```gdscript
class_name ContentValidationResult
extends RefCounted

var success: bool = true
var errors: Array[String] = []
var warnings: Array[String] = []

func add_error(message: String) -> void:
    success = false
    errors.append(message)

func add_warning(message: String) -> void:
    warnings.append(message)
```

#### 字段说明
- **success**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
#### 函数使用场景
- **add_error()**：添加操作。实际例子：玩家拾取药水时 add_item 把 ItemInstance 放入背包。
- **add_warning()**：添加操作。实际例子：玩家拾取药水时 add_item 把 ItemInstance 放入背包。

---

---

### 27.12 ContentRegistry 使用示例

#### 详细实际用例

- 真实场景：LootSystem 掷出 `item.potion_small` 后，通过 ContentRegistry 找到 `ItemDefinition`，再创建 `ItemInstance`。存档里也只保存 `item.potion_small`，不保存 Resource 路径。
- 怎么使用：所有可复用内容都用稳定 ID 查找。生成器、奖励、技能和掉落表都只引用 ID，不直接持有场景实例。
- 验证重点：`get("item.potion_small")` 返回正确资源；删除某个被引用的奖励或技能后，validate 阶段能指出缺失引用。
### 注册资源

```gdscript
var sword := preload("res://game/content/items/sword_iron.tres") as ItemDefinition
var registry := ServiceRegistry.get_service("content") as ContentRegistry
registry.register_resource(sword)
```

### 查询 ItemDefinition

```gdscript
var item_def := registry.get_resource("item.sword_iron") as ItemDefinition
print(item_def.display_name)
```

### 查询 AbilityDefinition

```gdscript
var ability_def := registry.get_resource("ability.fireball_basic") as AbilityDefinition
if ability_def != null:
    print("Cooldown: ", ability_def.cooldown)
```

---

---

---

### 27.13 ContentValidationResult 使用示例

#### 详细实际用例

- 真实场景：启动时发现两个物品都叫 `item.sword_iron`，ContentRegistry 返回 validation result，里面 success=false，errors 包含重复 ID 详情。
- 怎么使用：让校验结果成为启动门禁。开发版本可以 push_error 并阻止进主菜单，工具脚本可以把 errors 打印成清单。
- 验证重点：错误信息要能定位到具体 ID 和资源类型，否则内容越多越难查。
```gdscript
var result := registry.validate_all()
if not result.success:
    for error in result.errors:
        push_error(error)
for warning in result.warnings:
    push_warning(warning)
```

---

