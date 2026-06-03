# ContentRegistry

## 概念说明

ContentRegistry 是稳定内容 ID 到 Resource 定义的查找表。负责加载数据库、检查重复 ID、检查缺失引用，并提供按 ID 查找能力。存档、掉落表、技能和奖励都应该保存稳定 ID，而不是脆弱的场景路径或节点引用。

## 设计目的

作为全局内容定义的权威查找源，任何需要通过 ID 查找 Resource 的系统都通过此服务获取。启动时校验所有内容，尽早发现配置错误。

## 文件

`res://addons/mkit/kernel/registry/content_registry.gd`

## 接口

```gdscript
class_name ContentRegistry
extends Node
func load_database(database: ResourceDatabase) -> void
func register_resource(res: Resource) -> void
func get_resource(content_id: String) -> Resource
func get_typed_resource(content_id: String, expected_script: Script) -> Resource
func get_all_by_type(type_name: String) -> Array
func has(content_id: String) -> bool
func validate_all() -> ContentValidationResult
```

## 函数使用场景

- **load_database()**：批量加载入口。例：GameBootstrap 启动时对每个 ResourceDatabase 调用此方法，注册所有物品、技能、房间定义。
- **register_resource()**：单个注册入口。例：运行时动态注册临时内容。当前稳定 ID 字段包括 item_id、ability_id、status_id、room_id、upgrade_id、entity_definition_id、enemy_id、loot_table_id、reward_id、stat_id、quest_id、dialogue_id、shop_id、zone_id。
- **get_resource()**：按 ID 查找资源。例：LootSystem 掷出 `item.potion_small` 后通过此方法获取 ItemDefinition，再创建 ItemInstance。
- **get_typed_resource()**：带类型过滤的查找。例：AbilityController 获取 AbilityDefinition 时验证类型。
- **get_all_by_type()**：按类型获取所有资源。例：RewardSystem 获取所有 RewardDefinition 构建候选池。
- **has()**：检查 ID 是否存在。例：在查找前先做存在性检查，避免 warning。
- **validate_all()**：启动校验。例：GameBootstrap 加载所有内容后调用，若有重复 ID 或空 ID 则报错，阻止进入游戏。

## 使用示例

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
