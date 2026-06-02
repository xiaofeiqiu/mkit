# ContentValidationResult

## 概念说明

ContentValidationResult 是内容校验的结构化结果。负责收集错误和警告信息，并提供 success 标志供调用者快速判断。DebugOverlay、测试和启动流程需要知道内容是否配置正确。

## 设计目的

作为 ContentRegistry.validate_all() 的返回值，让启动流程能以门禁方式阻止带有配置错误的内容进入游戏。错误信息需包含具体 ID 和资源类型，方便定位问题。

## 文件

`res://addons/mkit/kernel/registry/content_validation_result.gd`

## 字段说明

- **success**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **errors**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **warnings**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name ContentValidationResult
extends RefCounted
var success: bool = true
var errors: Array[String] = []
var warnings: Array[String] = []
func add_error(message: String) -> void
func add_warning(message: String) -> void
```

## 函数使用场景

- **add_error()**：添加错误信息并将 success 设为 false。例：ContentRegistry 发现重复 item_id 时调用此方法记录具体 ID。
- **add_warning()**：添加警告信息，不影响 success。例：资源缺失可选字段时记录警告。

## 使用示例

### 启动时进行内容校验

```gdscript
var result := registry.validate_all()
if not result.success:
    for error in result.errors:
        push_error(error)
for warning in result.warnings:
    push_warning(warning)
```
