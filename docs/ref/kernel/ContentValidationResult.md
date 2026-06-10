# ContentValidationResult

**层：** Kernel  
**文件：** `addons/mkit/kernel/registry/content_validation_result.gd`  
**继承：** `extends RefCounted`

## 职责

`ContentService.validate_all()` 的返回值。`GameBootstrap` 在启动时调用校验，`success=false` 则 `push_error` 列出问题。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `success` | `bool` | `true` | 是否全部通过 |
| `errors` | `Array[String]` | `[]` | 错误列表 |
| `warnings` | `Array[String]` | `[]` | 警告列表 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `add_error(message: String) -> void` | — | 追加错误并置 `success=false` |
| `add_warning(message: String) -> void` | — | 追加警告（不影响 success）|

## 使用模式

### 最小示例（Level 1）

```gdscript
var content := Mkit.content()
var result := content.validate_all()
if not result.success:
    for e in result.errors:
        push_error(e)
```

## 相关

- → [ContentService](ContentService.md)（产生它）· [GameBootstrap](GameBootstrap.md)（启动时校验）
