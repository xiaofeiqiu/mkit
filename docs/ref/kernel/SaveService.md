# SaveService

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/save_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"save"`

## 职责

存读档协调者，也是项目里唯一的存读档 facade。

- `save_game` 会把场景树中的 `Saveable` 写入 `roots`，把 `EntitySaveAgent` 写入 `entities`。
- `load_game` 先恢复 `roots` / `scopes`，再恢复 `entities` 下的实体组件。
- `GameBootstrap` 启动时若存档存在会自动 `load_game`。

scope 写入用于“无完整场景树也能恢复”的关键状态（如世界 run / 区域等）。当前 schema 只支持 `roots` / `entities` / `scopes`；旧版 `payload` / `scope_manifest` / `save_scopes` 字段不再写入，也不再读旧档迁移。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `save_path` | `String`（@export）| `"user://save.json"` | 存档文件路径 |
| `save_version` | `int`（@export）| `1` | 当前存档版本 |
| `schema_version` | `int`（@export）| `2` | 存档 envelope schema 版本 |
| `game_version` | `String`（@export）| `"0.1.0"` | 写入存档的游戏版本号 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `save_game(root: Node) -> bool` | `bool` | 收集 `Saveable` / `EntitySaveAgent` 并写盘；`root == null` 时仍可通过注册 scope 保存 root 状态 |
| `load_game(root: Node) -> bool` | `bool` | 读文件并按 scope + roots + entities 回填 |
| `register_saveable_scope(provider: Saveable) -> void` | `void` | 注册显式 scope 提供者（用于场景树缺失恢复） |
| `unregister_saveable_scope(provider: Saveable) -> void` | `void` | 注销显式 scope 提供者 |
| `get_registered_scope_snapshot() -> Dictionary` | `Dictionary` | 获取当前 scope 注册快照 |

文件结构包含 `schema_version`、版本头、`roots`、`entities` 与 `scopes`：

```json
{
  "schema_version": 2,
  "save_version": 1,
  "game_version": "0.1.0",
  "profile_id": "profile_001",
  "roots": {
    "progression": {}
  },
  "entities": {
    "player": {
      "scene_path": "res://game/entities/player.tscn",
      "zone_id": "village",
      "components": {
        "HealthComponent": {}
      }
    }
  },
  "scopes": {
    "global": {
      "progression": {}
    }
  }
}
```

`roots` 内的 `save_id` 必须唯一，`entities` 内的 `entity_id` 必须唯一。同一个实体下的 component `get_save_key()` 也必须唯一；重复会让 `save_game` 返回 `false` 并发 `save_failed`。

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `save_completed` | `path: String` | 写盘成功 |
| `load_completed` | `path: String` | 读取并恢复成功 |
| `save_failed` | `path, reason` | 写盘失败 |
| `load_failed` | `path, reason` | 读取失败 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var save := Mkit.save()
save.save_game(get_tree().root)
```

### 典型场景（Level 2）

```gdscript
# 快速存读档 + 失败处理
var _save: SaveService = null

func _ready() -> void:
    _save = Mkit.save()
    if _save == null:
        push_error("SaveService 未注册（Bootstrap 是否已运行？）")
        return
    _save.save_failed.connect(func(path: String, reason: String):
        push_error("存档失败 %s: %s" % [path, reason])
    )

func _unhandled_input(event: InputEvent) -> void:
    if _save == null:
        return
    if event.is_action_pressed("quick_save"):
        # 成功路径
        if _save.save_game(get_tree().root):
            print("已存档")
    elif event.is_action_pressed("quick_load"):
        # 失败路径：文件不存在会发 load_failed，并返回 false
        if not _save.load_game(get_tree().root):
            print("没有存档可读")
```

> 关键：`SaveableComponent` 不会作为全局 root 保存。实体组件走 [EntitySaveAgent](EntitySaveAgent.md)，全局服务/系统状态走 [Saveable](Saveable.md)。`scope` 路径在场景树缺失恢复时提供兜底。

## 相关

- → [Saveable](Saveable.md) · [EntitySaveAgent](EntitySaveAgent.md) · [SaveableComponent](SaveableComponent.md)
- → [pipeline.md — Save / Load](../../pipeline.md#13-save--load) · [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
