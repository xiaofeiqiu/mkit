# Portal

**层：** Module  
**文件：** `addons/mkit/modules/world/portal.gd`  
**继承：** `extends Interactable`

## 职责

传送门：一个被交互时跳转到目标区域出生点的 `Interactable`。挂在交互 `Area2D` 下（命名 `Interactable`），无需写代码。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `target_zone_id` | `String` | `""` | 目标区域 |
| `target_spawn_id` | `String` | `"default"` | 目标出生点 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# Portal：target_zone_id="zone.forest", target_spawn_id="from_village"
# 交互即调 WorldService.go_to_zone
```

## 相关

- → [Interactable](Interactable.md) · [WorldService](WorldService.md) · [SpawnPoint](SpawnPoint.md)
