# ZoneDefinition

## 概念说明

ZoneDefinition 是一个区域（zone）的静态 Resource 配置。它把一个稳定 zone_id 映射到要加载的场景路径、展示名称、区域 BGM 和默认出生点。具体区域内容（村庄、野外、地牢）由游戏项目在 `game/` 中创建资源，addon 只提供通用区域结构。

## 设计目的

让"切换区域"成为数据驱动的查表操作：WorldRouter 只需要 zone_id 就能找到目标场景、落点和音乐，而不必在导航代码里硬编码场景路径或村名。

## 文件

`res://addons/mkit/modules/world/zone_definition.gd`

## 字段说明

- **zone_id**：区域稳定 ID。例：`zone.village`，供 ContentRegistry、存档和 WorldRouter 查找。
- **display_name**：区域显示名称。UI 或区域提示可直接读取。
- **scene_path**：区域对应的 `.tscn` 路径。WorldRouter 通过 SceneRouter 切换到此场景。
- **bgm_id**：区域背景音乐 ID。进入区域时 WorldRouter 调 AudioManager.play_music；为空时不切音乐。
- **default_spawn_id**：默认出生点 ID。go_to_zone 未显式指定 spawn_id 时使用此值定位 SpawnPoint。
- **tags**：区域标签。用于 UI 分类或游戏侧筛选。

## 接口

```gdscript
class_name ZoneDefinition
extends Resource
@export var zone_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var bgm_id: String = ""
@export var default_spawn_id: String = "default"
@export var tags: Array[String] = []
func get_resource_id() -> String
```

## 函数使用场景

- **`get_resource_id()`**：返回 `zone_id`，供 ContentRegistry 使用稳定 ID 索引区域定义。

ZoneDefinition 其余字段为纯数据，由 Inspector 配置后随资源注册到 ContentRegistry，运行时由 WorldRouter 读取以切场景、放落点、换 BGM。

## 使用示例

```gdscript
var village := ZoneDefinition.new()
village.zone_id = "zone.village"
village.display_name = "Village"
village.scene_path = "res://game/demo/village.tscn"
village.bgm_id = "bgm.village"
village.default_spawn_id = "village_gate"
```
