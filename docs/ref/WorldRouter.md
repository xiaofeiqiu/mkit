# WorldRouter

## 概念说明

WorldRouter 是世界导航域的运行时 Node，注册为 ServiceRegistry 的 `world` service。它包裹 Kernel 的 SceneRouter：按 zone_id 查 ZoneDefinition、切换到对应场景，并在切换完成后把持久化玩家移到匹配的 SpawnPoint、发出 zone_changed / zone_entered 事件、按区域切换 BGM。

## 设计目的

把"换区域"从一次裸的场景切换升级为带落点与上下文的导航：玩家是跨场景持久节点，区域场景只放 SpawnPoint / Portal；WorldRouter 负责在场景切换后收尾（放落点、发事件、换音乐），让任务系统能监听 zone_entered 推进"到达 X"目标，让 Audio 能按 zone 自动换 BGM。

## 文件

`res://addons/mkit/modules/world/world_router.gd`

## 字段说明

- **zone_changed**：区域切换收尾时发出，携带 from_zone_id 与 to_zone_id。
- **player_group**：持久玩家所在的组名，默认 `player`。WorldRouter 取该组首个成员作为落点放置对象。
- **spawn_group**：SpawnPoint 所在的组名，默认 `spawn_point`。
- **current_zone_id**：当前所在区域 ID；收尾后更新。
- **scene_router**：SceneRouter 引用，实际执行场景切换；为空时从 `scenes` service 懒加载。
- **content**：ContentRegistry 引用；为空时从 `content` service 懒加载。

## 接口

```gdscript
class_name WorldRouter
extends Node
signal zone_changed(from_zone_id: String, to_zone_id: String)
@export var player_group: String = "player"
@export var spawn_group: String = "spawn_point"
var current_zone_id: String = ""
var scene_router: SceneRouter = null
var content: ContentRegistry = null
func go_to_zone(zone_id: String, spawn_id: String = "") -> bool
func get_current_zone() -> ZoneDefinition
func get_zone(zone_id: String) -> ZoneDefinition
func place_player_at_spawn(spawn_id: String) -> bool
```

## 函数使用场景

- **`go_to_zone(zone_id, spawn_id)`**：Portal、脚本或 UI 请求换区域时调用。它查 ZoneDefinition、记录 pending zone/spawn（spawn_id 为空则用 ZoneDefinition.default_spawn_id），再调 SceneRouter.change_scene；定义缺失、无 scene_router 或切换失败时清空 pending 并返回 false。
- **`get_current_zone()`**：读取当前 zone 的 ZoneDefinition（按 current_zone_id 查表）。
- **`get_zone(zone_id)`**：从 ContentRegistry 读取 ZoneDefinition；zone_id 为空或内容缺失时返回 null。
- **`place_player_at_spawn(spawn_id)`**：在 spawn_group 中按 spawn_id 找 SpawnPoint，把 player_group 首个成员移到其 global_position；找不到落点或玩家时返回 false。
- **`_on_scene_changed` / `_finalize_zone_entry`**：内部收尾。SceneRouter 的 `change_scene` 是 deferred（scene_changed 早于树切换发出），故收尾用 `call_deferred` 推迟到新场景就绪后：放玩家落点、更新 current_zone_id、发 zone_changed、经 EventRouter 发 emit_zone_changed 与 `zone_entered` DomainEvent，最后按 ZoneDefinition.bgm_id 调 AudioManager.play_music。

## 使用示例

```gdscript
var world := ServiceRegistry.get_service("world") as WorldRouter
world.go_to_zone("zone.field", "field_entrance")
# 切换为 deferred，调用方在跳转后等一帧再断言落点/事件
await get_tree().process_frame
```
