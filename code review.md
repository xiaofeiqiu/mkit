# Code Review

Status: 未 address

Base: `main`
Target: 当前 `dev` 工作区相对 `main` 的差异
Review date: 2026-06-03

## Findings

未发现需要 address 的阻塞问题。

## Review Notes

- `AudioManager` 改为 `Saveable` 后，`save_id` 默认设为 `audio`，并通过 `SaveManager` 的现有 saveable 收集机制保存和恢复 `bus_volumes`。
- `play_music(music_id, fade_seconds)` 覆盖了立即切换、首次淡入、已有音乐淡出后切换再淡入、重复请求取消 pending tween、`stop_music()` 取消 tween 等路径。
- `set_bus_volume()` / `get_bus_volume()` 对空 bus 和不存在 bus 有拒绝路径，成功路径会同步 `AudioServer` 并记录可持久化状态。
- `docs/ref/AudioManager.md` 与 `spec/rpg-impl-plan.md` 已同步新增 public API、Saveable 行为和验证记录。
- 未发现 addon 引入 `game/` 上行依赖，也未发现具体游戏内容硬编码进 `addons/mkit/`。

## Verification

- `make ut-kernel`: 102/102 passed.
- `make ut-modules`: 198/198 passed. 输出包含既有 orphan / leak 报告，但退出码为 0。
- `make int`: 34/34 passed.
- `git diff --check main`: passed.
