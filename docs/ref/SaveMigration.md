# SaveMigration

## 概念说明

SaveMigration 是一个存档版本到下一个版本的数据转换规则。它声明 from_version/to_version，并把旧 save Dictionary 转成新结构。上线后字段会改名、模块会拆分；没有迁移规则，旧玩家存档会在读档时丢失或崩溃。

## 设计目的

把每次存档格式升级的转换逻辑封装为独立 Resource，使 SaveManager 可以通过版本号链式执行迁移，每次格式变更只需补一个新的 SaveMigration，而不需要修改旧的迁移或 Saveable 实现。

## 文件

`res://addons/mkit/kernel/save/save_migration.gd`

## 字段说明

- **from_version**：源版本。例：旧存档 save_version=1。
- **to_version**：目标版本。例：迁移完成后写成 save_version=2。

## 接口

```gdscript
class_name SaveMigration
extends Resource
@export var from_version: int = 1
@export var to_version: int = 2
func migrate(data: Dictionary) -> Dictionary
```

## 函数使用场景

- **`migrate(data)`**：SaveManager._migrate_data() 调用此方法，将输入数据复制后设置 save_version=to_version，再调用 `_migrate_impl()` 执行具体字段转换，返回迁移后的数据。
- **`_migrate_impl(data)`**：子类重写，实现具体的字段移动、改名或结构调整逻辑。例如把 `payload.player.gold` 移动到 `payload.progression.currencies.meta_currency`。

## 使用示例

### 版本 1 到 2 的迁移

```gdscript
class_name SaveMigrationV1ToV2
extends SaveMigration

func _migrate_impl(data: Dictionary) -> Dictionary:
    var payload: Dictionary = data.get("payload", {})
    var player: Dictionary = payload.get("player", {})
    var progression: Dictionary = payload.get("progression", {})
    var currencies: Dictionary = progression.get("currencies", {})
    # 把 player.gold 迁移到 progression.currencies.meta_currency
    currencies["meta_currency"] = int(player.get("gold", 0))
    progression["currencies"] = currencies
    payload["progression"] = progression
    data["payload"] = payload
    return data
```

### 在 SaveManager 中配置迁移链

```text
SaveManager.migrations = [
    preload("res://game/save/migrations/v1_to_v2.tres"),
    preload("res://game/save/migrations/v2_to_v3.tres")
]
SaveManager.save_version = 3
```
