# Compatibility

Mkit 当前目标 Godot 版本是 **Godot 4.6.3 stable**。本仓库的 CI、`project.godot` feature tag 和入门文档都以这个版本为准。

---

## 版本承诺

| 项目 | 当前值 | 说明 |
|------|--------|------|
| Godot | `4.6.3 stable` | 开发、测试和 CI 的目标版本 |
| Addon | `0.1.0` | `addons/mkit/plugin.cfg` 中的插件版本 |
| Save schema | `2` | `SaveService.CURRENT_SCHEMA_VERSION` |

`0.x` 阶段仍允许删改未稳定 API，但需要在仓库根目录的 `CHANGELOG.md` 记录 public 行为变化。公共 addon API、存档结构、文档示例和 CI 目标版本应在同一次变更中保持一致。

---

## 升级规则

- Godot patch 版本升级（如 `4.6.3` → `4.6.x`）应先跑 `make ut`、`make int`、`make demo-test` 和 `make docs-check`。
- Godot minor 版本升级（如 `4.6` → `4.7`）需要同步更新 `project.godot`、`.github/workflows/ci.yml`、`docs/getting_started.md`、`docs/readme.md`、`addons/mkit/README.md` 和 `addons/mkit/plugin.cfg`。
- 若存档 schema 升级，必须补 `_migrate_save_envelope()` 迁移测试，并在 `SaveService` 源码 `##` doc comment 中记录 envelope 变化，再运行 `make docs-api` 更新生成 reference。
