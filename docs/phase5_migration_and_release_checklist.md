# 阶段5：运行时/模块迁移与发布清单（2026-06-07）

本页用于收口 `mkit` 当前改版的运行时与模块迁移动作，作为阶段5发布前最后文档依据。

## 1. 运行时迁移规则（推荐）

### 新入口（推荐）

- 服务访问统一使用 `ServiceRegistry.get_port(ServiceRegistry.SERVICE_*)`。
- 在运行时初始化路径复杂的模块建议先做 `if` 保护并输出模块前缀日志。
- 新增模块应优先新增常量入口，或复用现有 `ServiceRegistry.SERVICE_*` 常量。

### 兼容入口（保留）

- `get_service` / `get_service_or_null` / `get_typed` 保留，不做强制移除。
- 适配旧样例、第三方脚本和历史教程时可继续使用兼容入口。
- 同一处逻辑中如出现新旧双入口，应先保持兼容再清理冗余。

## 2. 模块迁移对齐（运行时与文档）

1. `Saveable/SaveService` 迁移链：已同步 `scope` 与 `payload` 并在文档中收口。
2. `RunDirector/RunState/WorldService` 的 run/room/reward 持久化行为已收口到 scope 流程。
3. `ServiceRegistry` 对外文档（`docs/ref/kernel/ServiceRegistry.md`）已更新为 `get_port` 优先示例。
4. 架构与流水线文档已补齐 `SERVICE_*` 常量入口引用（`docs/architecture.md`、`docs/pipeline.md`）。
5. 错误与日志模板已统一（`docs/error_reporting.md`）。

## 3. 发布前检查清单

- [ ] `make demo-test`（检查启动、服务注册、兼容路径降级日志）
- [ ] `make ut`（单测闭环）
- [ ] `make int`（跨系统闭环）
- [ ] `make docs-check`（文档交叉引用与 ref 同步）
- [ ] 保存加载 smoke（含 run 进度回放 + room 清空后奖励恢复）
- [ ] 若存在兼容问题，回退到阶段4最后稳定提交并补充回归说明

## 4. 回滚预案（运行时）

1. 仅回退代码：保留 `get_service` 兼容，先撤销所有新入口引用（`get_port`）即可回到原有访问路径。
2. 回退版本：`git revert` 本阶段提交序列，保持数据库资源和 `game/` 配置不变。
3. 回归验证：重新执行 `make demo-test` 与关键 `make int` 案例，确认 `save_scope`/`run` 流程可用。

