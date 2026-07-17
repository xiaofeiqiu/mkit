class_name DamageRequest
extends RefCounted
## 说明：`DamageRequest` 是 战斗系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在战斗系统中复用这段契约或状态时使用它。
## 示例：`var instance := DamageRequest.new()`

## 产生本次行为或结果的节点引用；为空表示来源未绑定或不需要来源。
var source: Node = null
## 本次行为或结果作用的目标节点；为空表示尚未选定目标。
var target: Node = null
## 基础数值；在伤害或治疗结算中会被属性、倍率或规则进一步调整。
var base_amount: float = 0.0
## 伤害类型 id；用于抗性、格挡、事件标签或 UI 展示。
var damage_type: String = "physical"
## 元素类型 id；`none` 表示无元素，可用于弱点和抗性规则。
var element_type: String = "none"
## 本次伤害是否允许暴击；关闭后暴击率相关规则应跳过。
var can_crit: bool = true
## 本次伤害是否允许闪避；关闭后闪避相关规则应跳过。
var can_evade: bool = true
## 本次伤害是否允许格挡；关闭后格挡相关规则应跳过。
var can_block: bool = true
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
var tags: Array[String] = []
## 命中后尝试施加的状态配置列表；每项 Dictionary 应包含 status_id 等约定 key。
var on_hit_statuses: Array[Dictionary] = []
## 附加上下文数据；key 由创建该对象的系统约定，读取前应检查是否存在。
var payload: Dictionary = {}
