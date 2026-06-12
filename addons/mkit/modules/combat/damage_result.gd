class_name DamageResult
extends RefCounted
## 说明：`DamageResult` 是 战斗系统 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在战斗系统中复用这段契约或状态时使用它。
## 示例：`var instance := DamageResult.new()`

## 产生本次行为或结果的节点引用；为空表示来源未绑定或不需要来源。
var source: Node = null
## 本次行为或结果作用的目标节点；为空表示尚未选定目标。
var target: Node = null
## 基础数值；在伤害或治疗结算中会被属性、倍率或规则进一步调整。
var base_amount: float = 0.0
## 完成所有加成、减免和倍率后的最终伤害数值。
var final_amount: float = 0.0
## 伤害类型 id；用于抗性、格挡、事件标签或 UI 展示。
var damage_type: String = "physical"
## 元素类型 id；`none` 表示无元素，可用于弱点和抗性规则。
var element_type: String = "none"
## 结算结果是否暴击；用于 UI、音效和后续事件。
var was_critical: bool = false
## 结算结果是否被闪避；为 true 时通常不会造成生命值变化。
var was_evaded: bool = false
## 结算结果是否被格挡；可与 final_amount 一起表达减伤后结果。
var was_blocked: bool = false
## 本次伤害是否使目标死亡或达到死亡阈值。
var was_lethal: bool = false
## 本次结算成功施加的状态 id 列表。
var applied_status_effects: Array[String] = []
## 状态施加明细列表；每项 Dictionary 记录 status_id、stacks、source 等约定 key。
var status_applications: Array[Dictionary] = []
## 伤害结算追踪数据；key 由 CombatService 写入，用于调试公式和测试。
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
