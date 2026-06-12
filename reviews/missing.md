# 审核：docs/index.html「常用任务」缺失项

> 审核对象：`docs/index.html` 中 `NAV` 的「常用任务」组（index.html:206-212）
> 日期：2026-06-11

## 现状

目前只有 5 项：

| 条目 | 链接 |
|------|------|
| 做一个技能 | `cookbook/05_ability.md#步骤` |
| 做一个任务 | `cookbook/10_quest.md#步骤` |
| 做一个商店 | `cookbook/14_shop.md#步骤` |
| 做存档/读档 | `cookbook/11_progression_and_save.md#步骤` |
| 调试技能没效果 | `debugging.md#按症状选择工具` |

对照：mkit 有 **12 个模块**（ai、combat、dialogue、entity、interaction、inventory、loot、progression、quest、shop、ui、world），cookbook 有 **15 篇 Recipe**（每篇都有 `## 步骤` 锚点，可以直接深链）。常用任务只覆盖了其中 4 篇 Recipe + 1 个调试入口，覆盖率明显不足。

---

## 一、缺失的「做 X」类条目（文档已存在，加导航即可）

按 RPG 开发中的使用频率排序：

| 建议条目 | 链接 | 理由 |
|----------|------|------|
| 做一个敌人（AI） | `cookbook/06_ai_enemy.md#步骤` | 敌人是和技能同级的高频需求，主线 Recipe 之一 |
| 做一个攻击动作 | `cookbook/04_attack_action.md#步骤` | Action→Effect 是框架最核心的管线，比技能更基础 |
| 做一个 buff/DOT 状态效果 | `cookbook/12_status_effects.md#步骤` | 战斗系统的标配，目前完全没有入口 |
| 做 NPC 对话 | `cookbook/09_npc_dialogue.md#步骤` | dialogue 模块的唯一文档入口，且是接任务的前置 |
| 做掉落/奖励 | `cookbook/08_loot_and_rewards.md#步骤` | loot 模块的唯一文档入口 |
| 做一个玩家实体 | `cookbook/02_player_entity.md#步骤` | 新项目第一个实际任务；entity 模块入口 |
| 给实体加血量/属性 | `cookbook/03_health_and_stats.md#步骤` | 几乎所有实体都需要；伤害/死亡的前置 |
| 做一个房间/关卡推进 | `cookbook/07_room.md#步骤` | 主线 Recipe，房间清空→推进是核心 loop |
| 做区域跳转（Portal） | `cookbook/15_world_zone_transition.md#步骤` | world 模块的唯一文档入口 |
| 给实体接动画/VFX | `cookbook/13_animation.md#步骤` | 表现层接入是每个实体都会碰到的事 |
| 启动一个新项目 | `cookbook/01_bootstrap.md#步骤` | 第一次接触框架的人最需要的入口（也可认为 Getting Started 已覆盖，优先级低） |

## 二、缺失的「调试/排查」类条目

目前只有「调试技能没效果」一条，但 `debugging.md` 的「按症状选择工具」和「常见问题速查表」里实际覆盖了至少 5 类症状，每类都值得一个入口：

| 建议条目 | 链接 | 对应 debugging.md 内容 |
|----------|------|------|
| 调试按键/命令没反应 | `debugging.md#按症状选择工具` | Focus / Last command / CommandReceiver |
| 调试存档没有恢复 | `debugging.md#按症状选择工具` | save scope / get_save_id / load 顺序 |
| 调试事件没到 UI | `debugging.md#按症状选择工具` | EventService.recent_events |
| 调试场景/区域不切换 | `debugging.md#按症状选择工具` | WorldService / Portal / SceneService |
| 服务取到 null 怎么办 | `debugging.md#常见问题速查表` | Bootstrap 未运行 / 服务常量用错 |

注意：这 5 条目前都只能链到同一个锚点（症状表/速查表），区分度不高。如果觉得太挤，可以只加一条「**排查问题（按症状）**」总入口，替换现在过于具体的「调试技能没效果」。

## 三、文档本身就缺失的常用任务（需要先写文档，不只是加导航）

这些是模块存在、但没有任何 cookbook/指南覆盖的高频任务：

1. **做一个物品/背包** — `inventory` 模块存在，但物品只散见于 Recipe 08（掉落）和 14（商店），没有一篇讲「定义 ItemDefinition → 入背包 → 使用物品」的完整路径。这是 RPG 最高频任务之一，是最值得补的缺口。
2. **做一个交互区域** — `interaction` 模块没有专属 Recipe，交互区域只在 NPC 对话（09）里顺带出现。「踩上去触发 X」是通用需求。
3. **做一个 UI 面板/HUD** — `ui` 模块没有任何 cookbook；血条、技能栏 UI 都只在其他 Recipe 里捎带。
4. **配置升级/XP 曲线** — 埋在 Recipe 11 里和存档混在一起；progression 配置本身值得一个独立小节或锚点。
5. **写一个自定义服务/扩展事件目录** — 框架进阶用法（EventService 模块事件目录、ModuleBootstrap 组合）目前只有 architecture.md 的概念描述，没有操作步骤。

## 四、结构建议

11 + 5 条全加进去会让「常用任务」失去"快捷入口"的意义。建议：

1. **「常用任务」控制在 8–10 条**，按频率取舍。建议清单：

   ```js
   { group: '常用任务', items: [
     { label: '做一个玩家实体',     href: 'cookbook/02_player_entity.md#步骤' },
     { label: '做一个攻击动作',     href: 'cookbook/04_attack_action.md#步骤' },
     { label: '做一个技能',         href: 'cookbook/05_ability.md#步骤' },
     { label: '做一个敌人（AI）',   href: 'cookbook/06_ai_enemy.md#步骤' },
     { label: '做 buff/DOT',        href: 'cookbook/12_status_effects.md#步骤' },
     { label: '做 NPC 对话',        href: 'cookbook/09_npc_dialogue.md#步骤' },
     { label: '做一个任务',         href: 'cookbook/10_quest.md#步骤' },
     { label: '做一个商店',         href: 'cookbook/14_shop.md#步骤' },
     { label: '做存档/读档',        href: 'cookbook/11_progression_and_save.md#步骤' },
     { label: '排查问题（按症状）', href: 'debugging.md#按症状选择工具' },
   ]},
   ```

2. 其余条目（房间、掉落、动画、区域跳转、血量属性）通过 **Cookbook 组**（默认折叠，已存在）和**侧边栏搜索**可达，不必重复。
3. 调试类如果想保留多条，可以单独开一个「排查问题」组，而不是混在「做 X」里。
4. 中期补文档：优先写「做一个物品/背包」（第三节第 1 条），写完后加入常用任务。

## 五、顺带发现

- 所有 15 篇 Recipe 都有统一的 `## 步骤` 锚点，深链方案是可靠的，新增条目照抄 `#步骤` 即可。
- 搜索框 placeholder（"搜索：技能、任务、存档、Shop、Debug…"）提到的关键词均可命中现有 NAV，无需改动。
