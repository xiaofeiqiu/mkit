# DungeonGenerator

## 概念说明

DungeonGenerator 是确定性地牢图生成器。它根据 seed 和房间池生成线性路径、分支、Boss 房等 RoomGraph。确定性生成方便调试、存档、复现 bug 和未来做每日挑战。

## 设计目的

把地牢图的生成逻辑封装到独立的无状态服务类，使 RunDirector 只需传入参数即可获得可复现的 RoomGraph，而不需要在 Run 代码中散落随机选取逻辑。固定 seed 保证相同输入产生相同图结构。

## 文件

`res://addons/mkit/modules/run/dungeon_generator.gd`

## 接口

```gdscript
class_name DungeonGenerator
extends RefCounted

func generate_linear(room_pool_ids: Array[String], seed: int, length: int) -> RoomGraph: ...
```

## 函数使用场景

- **`generate_linear(room_pool_ids, seed, length)`**：生成长度为 length 的线性房间序列。每个位置用 `rng.randi_range` 从 room_pool_ids 中随机选取一个定义 ID，节点顺序连接，最后一个节点设为 boss_node。RunDirector.start_run() 调用此方法生成本局地图结构。

## 使用示例

```gdscript
var generator := DungeonGenerator.new()
var graph := generator.generate_linear([
    "room.dungeon_small_01",
    "room.dungeon_small_02",
    "room.treasure_01"
], 98765, 8)

for node in graph.nodes:
    print(node.node_id, " -> ", node.room_definition_id)

print("Start: ", graph.start_node.room_definition_id)
print("Boss: ", graph.boss_node.room_definition_id)
```
