class_name ContentDefinition
extends Resource
## 说明：`ContentDefinition` 是 内容注册 的内容定义基类，负责为可注册资源提供稳定 content id 契约。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在内容注册中复用这段契约或状态时使用它。
## 示例：`var instance := ContentDefinition.new()`


## 返回 ContentService 注册和查找使用的稳定 content id；id 为空时按该资源定义的备用字段处理。
func get_content_id() -> String:
	return ""
