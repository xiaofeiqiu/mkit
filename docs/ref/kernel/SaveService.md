# SaveService

**层：** Kernel  
**文件：** `addons/mkit/kernel/save/save_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"save"`

## 职责

存读档协调者。

- `save_game` 会把场景树中的 `Saveable` 与已注册 scope 提供者一起序列化为 JSON。
- `load_game` 在读取后先执行迁移链（`SaveMigration`），再按 scope（优先）与 legacy `payload` 恢复。
- `GameBootstrap` 启动时若存档存在会自动 `load_game`。

scope 写入用于“无完整场景树也能恢复”的关键状态（如世界 run / 房间 / 奖励等）。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `save_path` | `String`（@export）| `"user://save.json"` | 存档文件路径 |
| `save_version` | `int`（@export）| `1` | 当前存档版本 |
| `game_version` | `String`（@export）| `"0.1.0"` | 写入存档的游戏版本号 |
| `migrations` | `Array[SaveMigration]`（@export）| `[]` | 版本迁移链 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `save_game(root: Node) -> bool` | `bool` | 收集 `Saveable` 并写盘；`root == null` 时仍可通过注册 scope 保存 |
| `load_game(root: Node) -> bool` | `bool` | 读文件 -> 迁移 -> scope 与 payload 回填 |
| `register_saveable_scope(provider: Saveable) -> void` | `void` | 注册显式 scope 提供者（用于场景树缺失恢复） |
| `unregister_saveable_scope(provider: Saveable) -> void` | `void` | 注销显式 scope 提供者 |
| `get_registered_scope_snapshot() -> Dictionary` | `Dictionary` | 获取当前 scope 注册快照 |

> 实际文件结构会包含 `payload`（兼容旧读取路径）以及 `scopes`/`scope_manifest`（新路径）。

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
var save := ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
save.save_game(get_tree().root)
```

### 典型场景（Level 2）

```gdscript
# 快速存读档 + 失败处理
var _save: SaveService = null

func _ready() -> void:
    _save = ServiceRegistry.get_port(ServiceRegistry.SERVICE_SAVE) as SaveService
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

> 关键：`SaveableComponent` 仍需由 `Saveable` 聚合后才会入档。
> `scope` 路径在场景树缺失恢复时提供兜底。

## 相关

- → [Saveable](Saveable.md) · [SaveableComponent](SaveableComponent.md) · [SaveMigration](SaveMigration.md)
- → [pipeline.md — Save / Load](../../pipeline.md#13-save--load) · [cookbook/11_progression_and_save.md](../../cookbook/11_progression_and_save.md)
