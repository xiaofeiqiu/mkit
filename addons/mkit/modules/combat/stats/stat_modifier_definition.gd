class_name StatModifierDefinition
extends Resource
## 说明：`StatModifierDefinition` 是 属性系统 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `StatModifierDefinition` 资源，再通过 ContentService 按 id 查询。

## 公开枚举 `Operation`，限定 `StatModifierDefinition` 可接受的配置或运行时状态取值。
enum Operation { FLAT_ADD, PERCENT_ADD, PERCENT_MULTIPLY, OVERRIDE, CLAMP_MIN, CLAMP_MAX }
## 公开枚举 `StackingRule`，限定 `StatModifierDefinition` 可接受的配置或运行时状态取值。
enum StackingRule { STACK, REPLACE_SAME_SOURCE, HIGHEST_ONLY, LOWEST_ONLY, UNIQUE }
## 属性修饰定义的稳定 id；生成 StatModifier 时用于来源追踪和重复叠加判断。
@export var modifier_id: String = ""
## 引用的 StatDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var stat_id: String = ""
## 属性修饰运算类型；决定 value 是加法、倍率还是覆盖等规则。
@export var operation: Operation = Operation.FLAT_ADD
## 属性或修饰器数值；具体含义由 operation 或所在定义决定。
@export var value: float = 0.0
## 属性修饰应用优先级；数值越小越早参与计算。
@export var priority: int = 0
## 同源或同类修饰叠加规则；决定重复应用时覆盖、刷新还是累加。
@export var stacking_rule: StackingRule = StackingRule.STACK
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []
