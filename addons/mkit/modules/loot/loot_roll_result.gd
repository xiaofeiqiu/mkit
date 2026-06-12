class_name LootRollResult
extends RefCounted
## 说明：`LootRollResult` 是 掉落与奖励系统 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := LootRollResult.new()`

## 本次掉落实际生成的物品实例列表。
var item_instances: Array[ItemInstance] = []
## 本次掉落生成的货币表；key 为 currency id，value 为数量。
var currency: Dictionary = {}
## 掉落随机过程记录；用于调试权重、空掉落和条件过滤。
var debug_rolls: Array[Dictionary] = []
