class_name LootRollResult
extends RefCounted
## 说明：`LootRollResult` 是 掉落与奖励系统 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := LootRollResult.new()`

## 运行时状态：`item_instances` 表示 `LootRollResult` 的字段值，由 `LootRollResult` 的公开 API 读取或维护。
var item_instances: Array[ItemInstance] = []
## 运行时状态：`currency` 表示 `LootRollResult` 的字段值，由 `LootRollResult` 的公开 API 读取或维护。
var currency: Dictionary = {}
## 运行时状态：`debug_rolls` 表示 `LootRollResult` 的字段值，由 `LootRollResult` 的公开 API 读取或维护。
var debug_rolls: Array[Dictionary] = []
