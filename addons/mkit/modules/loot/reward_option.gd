class_name RewardOption
extends RefCounted
## 说明：`RewardOption` 是 掉落与奖励系统 的选项对象，负责表达玩家或系统可选择的一项结果。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := RewardOption.new()`

## 奖励定义 id；用于奖励池、UI 选择和事件归因。
var reward_id: String = ""
## UI 和编辑器中显示的名称；不参与内容 id 注册，留空时调用方可回退到稳定 id。
var display_name: String = ""
## 面向玩家或设计者的说明文本；用于 UI、提示和文档，不参与规则判定。
var description: String = ""
## UI 展示用图标资源；为 null 时界面应使用默认图标或隐藏图标位。
var icon: Texture2D = null
## 稀有度字符串；用于 UI 样式、掉落权重或奖励展示。
var rarity: String = "common"
## 奖励来源标识；用于 UI 或调试区分来自房间、任务、商店等来源。
var source: String = ""
## 条件通过后按顺序执行的效果列表；每个元素应为 GameEffect 资源。
var effects: Array[GameEffect] = []
## 附加上下文数据；key 由创建该对象的系统约定，读取前应检查是否存在。
var payload: Dictionary = {}
