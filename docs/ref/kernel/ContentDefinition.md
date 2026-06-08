# ContentDefinition

**层：** Kernel  
**文件：** `addons/mkit/kernel/registry/content_definition.gd`  
**继承：** `extends Resource`

## 职责

所有"可配置内容"的基类。任何要被 `ContentService` 按 id 查询的 `.tres`（技能、物品、房间、任务、对话、音频…）都继承它，并 override `get_content_id()` 返回唯一字符串。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_content_id() -> String` | `String` | **子类必须 override**，返回全局唯一 id，默认 `""` |

> 返回空串会在 `ContentService.register_resource` 时报 `Resource missing stable content id`；id 重复会报 `Duplicate content id`。

## 使用模式

### 最小示例（Level 1）

```gdscript
class_name WeaponDefinition
extends ContentDefinition

@export var weapon_id: String = ""
@export var damage: float = 10.0

func get_content_id() -> String:
    return weapon_id
```

## 相关

- → [ContentService](ContentService.md)（注册/查询）· [ResourceDatabase](ResourceDatabase.md)（打包入库）
- → [concepts.md — 模型 3：内容注册与查询](../../concepts.md#模型-3内容注册与查询contentservice--resourcedatabase)
