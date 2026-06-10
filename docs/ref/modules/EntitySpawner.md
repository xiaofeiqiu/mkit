# EntitySpawner

**层：** Module  
**文件：** `addons/mkit/modules/entity/entity_spawner.gd`  
**继承：** `extends Node`

## 职责

按 `EntityDefinition` 在运行时生成实体：加载场景 → 注入身份（faction/tags/definition_id/entity_id）→ 配置 `CommandReceiver` → 用 `base_stats` 覆盖属性 → 挂入树 → 注册起始技能。`RoomController` 用它 spawn 敌人。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `spawn_entity(definition_id, parent, position := Vector2.ZERO, runtime_id := "") -> Node` | `Node` | 生成实体，失败返回 `null` |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `entity_spawned` | `entity, definition_id` | 生成成功 |
| `entity_spawn_failed` | `definition_id, reason` | 失败（`missing_definition` / `missing_scene_path` / `cannot_instantiate_scene` …）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var enemy := ($EntitySpawner as EntitySpawner).spawn_entity("enemy.field_beast", $Enemies, Vector2(120, 80))
```

### 典型场景（Level 2）

```gdscript
# 波次生成，处理失败
func spawn_wave(ids: Array[String]) -> void:
    var spawner := $EntitySpawner as EntitySpawner
    spawner.entity_spawn_failed.connect(func(def_id: String, reason: String):
        push_warning("spawn 失败 %s: %s" % [def_id, reason])
    )
    var x := 0.0
    for id in ids:
        var e := spawner.spawn_entity(id, $Enemies, Vector2(x, 0))
        if e != null:
            x += 64.0
```

## 相关

- → [EntityDefinition](EntityDefinition.md) · [EntityIdentity](../kernel/EntityIdentity.md) · [ref/modules/RoomController.md](RoomController.md)
- → [pipeline.md — Entity Spawn](../../pipeline.md#9-entity-spawn) · [cookbook/07_room.md](../../cookbook/07_room.md)
