# ResourceDatabase

## 概念说明

ResourceDatabase 是一组内容资源的数据库 Resource。负责把物品、技能、敌人、房间、奖励、状态等资源批量交给 ContentRegistry 加载。大型 RPG/roguelike 内容很多，手动在代码里逐个注册资源不可维护。

## 设计目的

按内容域拆分数据库（items、abilities、rooms 等分别一个 .tres），在 GameBootstrap 的 `resource_databases` 数组中批量配置。运行时由 ContentRegistry 遍历所有数据库注册资源。

## 文件

`res://addons/mkit/kernel/registry/resource_database.gd`

## 字段说明

- **database_id**：稳定 ID 字段。例：ResourceDatabase 通过 database_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **resources**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **resource_paths**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name ResourceDatabase
extends Resource
@export var database_id: String = ""
@export var resources: Array[Resource] = []
@export var resource_paths: Array[String] = []
func get_all_resources() -> Array[Resource]
```

## 函数使用场景

- **get_all_resources()**：返回 `resources` 数组与通过 `resource_paths` 按路径加载的资源的合并列表。例：ContentRegistry.load_database 调用此方法获取全部资源进行注册。

## 使用示例

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
