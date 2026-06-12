# 错误码与日志模板

为便于排障与回归，mkit 建议统一使用三类日志/错误口径：

## 1. 系统错误（`push_error`）

- 用于必须中断或回退路径的错误。
- 建议包含模块名与失败动作，便于快速检索。

示例：

```gdscript
push_error("[WorldService] save load failed: save file missing")
push_error("[ServiceRegistry] Required service not found: %s" % service_id)
```

## 2. 降级提示（`push_warning`）

- 用于降级、回退和冗余路径触发的场景。
- 关键是保留上下文，避免“silent fallback”。

示例：

```gdscript
push_warning("[SaveService] Missing scoped payload id; using scene payload restore")
push_warning("[SaveService] register_saveable_scope skipped: provider is null")
```

## 3. 成功事件（`signal`）

- `save_completed` / `load_completed` 应提供最小上下文。
- 结合 `path` / `reason` 输出到统一监听层（UI 或调试面板）。

示例：

```gdscript
save_completed.connect(func(path: String):
    print("[SaveService] save completed: %s" % path)
)
```

## 当前收口建议

- 新增降级提示统一使用模块前缀，便于 `make docs-check` 与回归日志检索。
- service lookup 缺失、实体契约缺失、save scope 缺失这三类问题要保留可搜索上下文，例如 service id、entity name、scope name。
