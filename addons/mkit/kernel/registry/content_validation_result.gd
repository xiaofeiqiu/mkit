class_name ContentValidationResult
extends RefCounted
## 说明：`ContentValidationResult` 是 内容注册 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在内容注册中复用这段契约或状态时使用它。
## 示例：`var instance := ContentValidationResult.new()`

## 执行或校验是否成功；失败时同时查看 errors、warnings 或 failure_reason。
var success: bool = true
## 阻止内容通过校验的错误列表；为空表示没有致命问题。
var errors: Array[String] = []
## 允许继续运行但需要设计者检查的警告列表。
var warnings: Array[String] = []


## 向当前集合或状态加入传入数据；重复项按该对象规则合并或覆盖。
func add_error(message: String) -> void:
	success = false
	errors.append(message)


## 向当前集合或状态加入传入数据；重复项按该对象规则合并或覆盖。
func add_warning(message: String) -> void:
	warnings.append(message)
