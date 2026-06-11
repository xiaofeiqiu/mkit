class_name DamageResult
extends RefCounted
## 说明：`DamageResult` 是 战斗系统 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在战斗系统中复用这段契约或状态时使用它。
## 示例：`var instance := DamageResult.new()`

## 运行时状态：`source` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var source: Node = null
## 运行时状态：`target` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var target: Node = null
## 运行时状态：`base_amount` 表示数量值，由 `DamageResult` 的公开 API 读取或维护。
var base_amount: float = 0.0
## 运行时状态：`final_amount` 表示数量值，由 `DamageResult` 的公开 API 读取或维护。
var final_amount: float = 0.0
## 运行时状态：`damage_type` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var damage_type: String = "physical"
## 运行时状态：`element_type` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var element_type: String = "none"
## 运行时状态：`was_critical` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var was_critical: bool = false
## 运行时状态：`was_evaded` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var was_evaded: bool = false
## 运行时状态：`was_blocked` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var was_blocked: bool = false
## 运行时状态：`was_lethal` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var was_lethal: bool = false
## 运行时状态：`applied_status_effects` 表示效果列表，由 `DamageResult` 的公开 API 读取或维护。
var applied_status_effects: Array[String] = []
## 运行时状态：`status_applications` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var status_applications: Array[Dictionary] = []
## 运行时状态：`trace` 表示 `DamageResult` 的字段值，由 `DamageResult` 的公开 API 读取或维护。
var trace: Dictionary = {}


## 执行 `to_debug_dict` 对应的公开操作，并保持 `DamageResult` 的领域契约一致。
func to_debug_dict() -> Dictionary:
	return {
		"base_amount": base_amount,
		"final_amount": final_amount,
		"damage_type": damage_type,
		"element_type": element_type,
		"critical": was_critical,
		"evaded": was_evaded,
		"blocked": was_blocked,
		"lethal": was_lethal,
		"applied_status_effects": applied_status_effects,
		"trace": trace
	}
