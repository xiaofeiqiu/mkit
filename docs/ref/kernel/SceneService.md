# SceneService

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/scene_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"scenes"`

## 职责

场景切换的统一入口，带重入锁与切换信号。`GameBootstrap` 进入初始场景、`WorldService` 切区域都走它。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `current_scene_path` | `String` | `""` | 最近成功切换到的场景 |
| `transition_locked` | `bool` | `false` | 切换进行中（防重入）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `change_scene(scene_path: String) -> bool` | `bool` | 切换到目标场景，成功返回 true |
| `reload_current_scene() -> bool` | `bool` | 重新加载当前场景 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `scene_change_requested` | `scene_path` | 切换开始 |
| `scene_changed` | `scene_path` | 切换成功 |
| `scene_change_failed` | `scene_path, reason` | 失败（锁定/空路径/错误码）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var scenes := Mkit.scenes()
if not scenes.change_scene("res://game/scenes/level_2.tscn"):
    push_error("场景切换失败")
```

## 相关

- → [GameBootstrap](GameBootstrap.md)（进入初始场景）· [ref/modules/WorldService.md](../modules/WorldService.md)
- → [pipeline.md — Scene / Zone Transition](../../pipeline.md#20-scene--zone-transition) · [cookbook/15_world_zone_transition.md](../../cookbook/15_world_zone_transition.md)
