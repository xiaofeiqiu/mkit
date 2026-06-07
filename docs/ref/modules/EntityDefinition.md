# EntityDefinition

**层：** Module  
**文件：** `addons/mkit/modules/entity/entity_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

实体的可配置蓝图（`.tres`）：场景路径、默认阵营、基础属性、起始技能、掉落表。`EntitySpawner.spawn_entity(id, ...)` 按它实例化并注入。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `entity_definition_id` | `String` | `""` | 唯一 id（`get_content_id` 返回它）|
| `display_name` | `String` | `""` | 显示名 |
| `scene_path` | `String` | `""` | 实体场景路径 |
| `default_faction` | `String` | `"neutral"` | 默认阵营 |
| `tags` | `Array[String]` | `[]` | 标签 |
| `base_stats` | `Dictionary` | `{}` | 覆盖 `StatsComponent` 基础值 |
| `starting_ability_ids` | `Array[String]` | `[]` | 起始技能 |
| `loot_table_id` | `String` | `""` | 掉落表 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# .tres：entity_definition_id="enemy.field_beast"，scene_path=敌人场景，base_stats={"max_hp":60}
var spawner := $EntitySpawner as EntitySpawner
spawner.spawn_entity("enemy.field_beast", $Enemies, Vector2(100, 0))
```

## 相关

- → [EntitySpawner](EntitySpawner.md) · [EntityIdentity](EntityIdentity.md)
- → [cookbook/07_room.md](../../cookbook/07_room.md)
