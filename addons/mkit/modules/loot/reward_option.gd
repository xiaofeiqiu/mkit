class_name RewardOption
extends RefCounted
## 说明：`RewardOption` 是 掉落与奖励系统 的选项对象，负责表达玩家或系统可选择的一项结果。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在掉落与奖励系统中复用这段契约或状态时使用它。
## 示例：`var instance := RewardOption.new()`

## 运行时状态：`reward_id` 表示稳定 id，由 `RewardOption` 的公开 API 读取或维护。
var reward_id: String = ""
## 运行时状态：`display_name` 表示面向玩家或编辑器的显示名，由 `RewardOption` 的公开 API 读取或维护。
var display_name: String = ""
## 运行时状态：`description` 表示说明文本，由 `RewardOption` 的公开 API 读取或维护。
var description: String = ""
## 运行时状态：`icon` 表示 `RewardOption` 的字段值，由 `RewardOption` 的公开 API 读取或维护。
var icon: Texture2D = null
## 运行时状态：`rarity` 表示 `RewardOption` 的字段值，由 `RewardOption` 的公开 API 读取或维护。
var rarity: String = "common"
## 运行时状态：`source` 表示 `RewardOption` 的字段值，由 `RewardOption` 的公开 API 读取或维护。
var source: String = ""
## 运行时状态：`effects` 表示效果列表，由 `RewardOption` 的公开 API 读取或维护。
var effects: Array[GameEffect] = []
## 运行时状态：`payload` 表示事件或存档载荷，由 `RewardOption` 的公开 API 读取或维护。
var payload: Dictionary = {}
