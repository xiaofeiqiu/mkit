# Cookbook

Cookbook 是一条**单一项目的累进构建主线**。每篇 Recipe 在上一篇已有场景的基础上新增一层，做完 Recipe 01–11 就得到一个完整可玩的 RPG loop。Recipe 12–14 是独立扩展，可按需选做。

---

## 通用开发流程

每次为 mkit 游戏添加一个新系统（技能、任务、物品…），都遵循同一条路径：

```mermaid
flowchart LR
    A["① 定义数据\nContentDefinition\n(.tres)"]:::userOwned -->
    B["② 注册内容\nResourceDatabase\n挂到 GameBootstrap"]:::userOwned -->
    C["③ 启动 / Boot\nGameBootstrap 创建 RuntimeContext\n注册 service ports\n加载并校验内容"]:::mkitCore -->
    D["④ 构建实体\nEntityRoot 默认布局\nEntityContract 访问组件/控制器"]:::userOwned -->
    E["⑤ 发出命令\nGameCommand\n→ CommandService"]:::userOwned -->
    F["⑥ 状态决策\nStateMachine\nState.handle_command"]:::mkitCore -->
    G["⑦ 执行动作\nGameAction\n_on_start/_on_complete"]:::userOwned -->
    H["⑧ 触发效果\nGameEffect\n_apply_impl"]:::userOwned -->
    I["⑨ 广播事件\nEventService\nUI / Audio / VFX 订阅"]:::mkitCore

    classDef mkitCore  fill:#4A90D9,color:#fff,stroke:#2C6FAC
    classDef userOwned fill:#7ED321,color:#fff,stroke:#5A9A18
```

> 🔵 蓝色 = mkit 负责 / 🟢 绿色 = 你实现

**每一步做什么：**

| 步骤 | 你做什么 | mkit 做什么 |
|------|----------|------------|
| ① 定义数据 | 继承 `ContentDefinition`，加 `@export` 字段，设 `get_content_id()` | — |
| ② 注册内容 | 把 `.tres` 文件放入 `ResourceDatabase.resources` | — |
| ③ Boot | 挂好 `GameBootstrap` 并设 `resource_databases` | 创建 `MkitRuntimeContext`，注册 runtime ports，加载内容，校验 ID 唯一性 |
| ④ 构建实体 | 在场景树搭 EntityRoot / Components / Controllers | `EntityContract` / `EntityRoot` 提供组件和控制器语义入口 |
| ⑤ 发出命令 | `GameCommand.create("attack", player_id, enemy_id)` → `CommandService.dispatch` | 路由到目标实体的 `CommandReceiver` |
| ⑥ 状态决策 | 在 `State.handle_command` 返回 `true`/`false`，决定是否响应 | HFSM 从叶往根冒泡找第一个处理者 |
| ⑦ 执行动作 | 继承 `GameAction`，override `_on_start/_on_update/_on_complete` | `ActionService` 管理生命周期，钩子后自动 `_fire_effects` |
| ⑧ 触发效果 | 继承 `GameEffect`，override `_apply_impl`，修改组件数据 | `EffectService` 检查 conditions，包装 `EffectResult` |
| ⑨ 广播事件 | 调用 `EventService.emit_*` | 通过信号通知所有订阅者（UI、Audio、VFX）|

**最精简的路径（不需要全部步骤）：**
- 只需一个瞬时效果？跳过 ③④⑤⑥⑦，直接用 `EffectService.execute(effect, ctx)`
- 只需一个 AI 命令？Brain 直接调 `issue_command()`，跳过输入层
- 只需监听事件？订阅 `EventService` 信号，不需要任何实体

---

## 主线路径

```
Recipe 01  → 游戏启动，services 在线                    ★☆☆  约 15 min
Recipe 02  → 玩家实体出现在场景，可以移动               ★★☆  约 30 min
Recipe 03  → 玩家有血量/属性，可以被伤害和死亡          ★★☆  约 25 min
Recipe 04  → 玩家有攻击动作，能命中区域造成伤害         ★★★  约 30 min
Recipe 05  → 玩家有可配置技能（AbilityDefinition），可 cast  ★★★  约 30 min
Recipe 06  → 敌人实体上场，有 AI，会主动攻击玩家        ★★★  约 25 min
Recipe 07  → 战斗发生在房间里，房间清空后推进           ★★★  约 35 min
Recipe 08  → 房间清空触发奖励选择（Loot + UI）           ★★★  约 30 min
Recipe 09  → NPC 可以对话，对话结束后接受任务           ★★★  约 30 min
Recipe 10  → 击杀敌人推进任务目标，完成任务领奖励       ★★★  约 25 min
Recipe 11  → 击杀/完成任务获得 XP，升级，全局存读档     ★★★  约 35 min
           ↑ 完整 RPG loop
Recipe 12  → 为技能添加状态效果（DOT / buff）            ★★☆  约 20 min  [扩展]
Recipe 13  → 为实体接入动画（Action 驱动 + 事件 VFX）   ★★☆  约 20 min  [扩展]
Recipe 14  → 在房间之间开放商店购买物品                 ★★☆  约 20 min  [扩展]
```

---

## 前置条件

所有主线 Recipe 都假设你已经完成了 [getting_started.md](../getting_started.md) 的步骤：
- Godot 4.x 项目
- `addons/mkit/` 已复制并启用插件
- `ServiceRegistry` 已加为 autoload

---

## 相关文档

- [架构层模型](../architecture.md) — 理解 Game Content / Mkit Modules / Kernel Runtime / Platform Adapters 分层
- [核心心智模型](../concepts.md) — 5 个模型，读完再开始
- [管线参考](../pipeline.md) — 每条管线的完整调用序列
- [调试工具](../debugging.md) — 遇到问题时的第一查阅点
