class_name DamageRequest
extends RefCounted
## 说明：`DamageRequest` 是 战斗系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在战斗系统中复用这段契约或状态时使用它。
## 示例：`var instance := DamageRequest.new()`

## 运行时状态：`source` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var source: Node = null
## 运行时状态：`target` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var target: Node = null
## 运行时状态：`base_amount` 表示数量值，由 `DamageRequest` 的公开 API 读取或维护。
var base_amount: float = 0.0
## 运行时状态：`damage_type` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var damage_type: String = "physical"
## 运行时状态：`element_type` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var element_type: String = "none"
## 运行时状态：`can_crit` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var can_crit: bool = true
## 运行时状态：`can_evade` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var can_evade: bool = true
## 运行时状态：`can_block` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var can_block: bool = true
## 运行时状态：`tags` 表示标签集合，由 `DamageRequest` 的公开 API 读取或维护。
var tags: Array[String] = []
## 运行时状态：`on_hit_statuses` 表示 `DamageRequest` 的字段值，由 `DamageRequest` 的公开 API 读取或维护。
var on_hit_statuses: Array[Dictionary] = []
## 运行时状态：`payload` 表示事件或存档载荷，由 `DamageRequest` 的公开 API 读取或维护。
var payload: Dictionary = {}
