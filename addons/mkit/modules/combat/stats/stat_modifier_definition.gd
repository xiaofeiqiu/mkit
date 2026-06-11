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
## 编辑器配置：`modifier_id` 表示稳定 id，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var modifier_id: String = ""
## 编辑器配置：`stat_id` 表示稳定 id，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var stat_id: String = ""
## 编辑器配置：`operation` 表示 `StatModifierDefinition` 的字段值，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var operation: Operation = Operation.FLAT_ADD
## 编辑器配置：`value` 表示 `StatModifierDefinition` 的字段值，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var value: float = 0.0
## 编辑器配置：`priority` 表示 `StatModifierDefinition` 的字段值，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var priority: int = 0
## 编辑器配置：`stacking_rule` 表示 `StatModifierDefinition` 的字段值，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var stacking_rule: StackingRule = StackingRule.STACK
## 编辑器配置：`tags` 表示标签集合，由 `StatModifierDefinition` 的公开 API 读取或维护。
@export var tags: Array[String] = []
