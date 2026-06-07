# EntityIdentity

**层：** Module  
**文件：** `addons/mkit/modules/entity/entity_identity.gd`  
**继承：** `extends Node`

## 职责

实体的身份名片：唯一 id、阵营、标签。`CommandService` 路由、`CombatService` 阵营判定、`QuestService` 击杀匹配都靠它。必须是 `EntityIdentity` 命名的子节点。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `entity_id` | `String` | `""` | 唯一 id；空则 `_ready` 自动生成 |
| `definition_id` | `String` | `""` | 来源 `EntityDefinition` id（spawn 时注入）|
| `display_name` | `String` | `""` | 显示名 |
| `faction` | `String` | `"neutral"` | 阵营（`player` / `enemy` / `npc`）|
| `tags` | `Array[String]` | `[]` | 标签 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `has_tag(tag) -> bool` | `bool` | 是否含某标签 |
| `has_any_tag(input_tags) -> bool` | `bool` | 是否含任一标签 |
| `is_faction(value) -> bool` | `bool` | 阵营匹配 |

## 使用模式

### 最小示例（Level 1）

```gdscript
var idn := entity.get_node("EntityIdentity") as EntityIdentity
if idn.is_faction("enemy"):
    print("敌对：%s" % idn.entity_id)
```

## 相关

- → [EntityRoot](EntityRoot.md) · [EntityDefinition](EntityDefinition.md)
- → [ref/modules/QuestService.md](QuestService.md)（按 faction/tags/definition_id 匹配击杀）
