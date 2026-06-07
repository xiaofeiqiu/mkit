# SaveMigration

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/save_migration.gd`  
**继承：** `extends Resource`

## 职责

把旧版本存档升级到新版本的迁移单元。`SaveService` 在 `load_game` 时按 `from_version → to_version` 逐步串联迁移，直到达到当前 `save_version`。  
当前版本保留兼容：会同时维护 `payload` 与 `scopes`，旧存档可仅保留 `payload`。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `from_version` | `int`（@export）| `1` | 适用的源版本 |
| `to_version` | `int`（@export）| `2` | 迁移到的目标版本 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `migrate(data: Dictionary) -> Dictionary` | `Dictionary` | 复制数据、写入新 `save_version`、调 `_migrate_impl` |
| `_migrate_impl(data: Dictionary) -> Dictionary` | `Dictionary` | **子类实现** 实际字段改写，默认原样返回 |

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name MigrateV1ToV2
extends SaveMigration
# Inspector: from_version = 1, to_version = 2

func _migrate_impl(data: Dictionary) -> Dictionary:
    var payload: Dictionary = data.get("payload", {})
    # 例：把旧的 "hp" 字段重命名为 "current_hp"
    if payload.has("player") and payload["player"].has("hp"):
        payload["player"]["current_hp"] = payload["player"]["hp"]
        payload["player"].erase("hp")
    data["payload"] = payload
    return data
```

把它加进 `SaveService.migrations`，并把 `save_version` 提到 `2`。

## 相关

- → [SaveService](SaveService.md)（按链调用迁移）
