# 错误码与日志模板（阶段5收口草案）

为便于排障与回归，mkit 建议统一使用三类日志/错误口径：

## 1. 系统错误（`push_error`）

- 用于必须中断或回退路径的错误。
- 建议包含模块名与失败动作，便于快速检索。

示例：

```gdscript
push_error("[WorldService] save load failed: save file missing")
push_error("[ServiceRegistry] Required service not found: %s" % service_id)
```

## 2. 兼容提示（`push_warning`）

- 用于降级、兼容、冗余路径被触发的场景。
- 关键是保留上下文，避免“silent fallback”。

示例：

```gdscript
push_warning("[SaveService] Missing legacy payload id; using scope restore")
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

## 阶段5收口建议

- 仍需兼容的 API 保留原有日志语义，但新增功能优先增加模块前缀。
- 新增迁移或弃用提示统一使用模块前缀，便于 `make docs-check` 与回归日志检索。
