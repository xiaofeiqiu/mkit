# Addon 结构重组计划

**范围：** `addons/mkit/kernel/` 和 `addons/mkit/modules/`
**目标：** 每个模块对应一个游戏设计问题域；Kernel 零模块依赖；模块从 17 个收拢到 12 个。

---

## 前提决策

### Bootstrap 豁免

`kernel/bootstrap/game_bootstrap.gd` 是整个系统的组合根（composition root），负责把所有 service 实例化并注入 ServiceRegistry。它天然需要引用所有模块 service 的 class_name（`CombatService`、`ProgressionService`、`QuestService`、`ShopService`、`DialogueService`、`WorldService`、`LootSystem` 等）。

**决策：`game_bootstrap.gd` 豁免于"Kernel 零模块依赖"规则。** 其余 kernel 文件（effects/builtin、conditions/builtin、actions/builtin、services、events、commands 等）必须零模块依赖。

推论：P0 验收、P5.3 CI 检查均需将 `game_bootstrap.gd` 排除在外。

### P0 验收 grep 的局限性

GDScript 通过全局 class_name 解析类型，不使用路径 import，因此 `grep -r "modules/"` **今天就已经返回空**，但 kernel builtins 对模块类（`HealthComponent`、`AbilityController` 等）的类型引用依然存在。P0 验收必须同时检查 class_name 引用，见下方修订后的验收命令。

---

## 问题域划分

| 模块 | 对应的游戏设计问题 | 现有模块归入 |
|---|---|---|
| `entity/` | 世界里存在什么？ | entity |
| `ai/` | 实体如何决策？ | ai |
| `interaction/` | 玩家如何与世界对象交互？ | interaction |
| `combat/` | 实体如何战斗？ | stats + health + abilities + status_effects + combat |
| `inventory/` | 实体携带什么？ | inventory |
| `progression/` | 玩家如何成长？ | progression |
| `shop/` | 玩家如何购买？ | shop |
| `loot/` | 玩家如何获得掉落？ | loot |
| `world/` | 事情发生在哪里？ | room + world |
| `quest/` | 故事任务是什么？ | quest |
| `dialogue/` | NPC 说什么？ | dialogue |
| `ui/` | 玩家如何感知游戏？ | ui |

---

## 进度追踪

**Phase 0 — 修 Kernel 污染（前置，必须最先完成）**
- [x] P0.1 `kernel/effects/builtin/deal_damage_effect.gd` → `modules/combat/damage/`
- [x] P0.2 `kernel/effects/builtin/heal_effect.gd` → `modules/combat/health/`
- [x] P0.3 `kernel/effects/builtin/apply_stat_modifier_effect.gd` → `modules/combat/stats/`
- [x] P0.4 `kernel/effects/builtin/apply_status_effect.gd` → `modules/combat/status_effects/`
- [x] P0.5 `kernel/effects/builtin/grant_item_effect.gd` → `modules/inventory/`
- [x] P0.6 `kernel/conditions/builtin/cooldown_ready_condition.gd` → `modules/combat/abilities/`
- [x] P0.7 `modules/ui/audio_service.gd` → `kernel/services/`（AudioService extends Saveable，属平台 service，与其他 kernel/services/ 同层）
- [x] P0.8 `game_bootstrap.gd` 中 `AudioService` 的注册已无需改动（class_name 全局解析）；确认移动后 .godot 类缓存刷新（`godot --headless --import`）
- [x] P0.9 `kernel/actions/builtin/` 三个文件移入 `modules/combat/`：
  - `cast_action.gd` → `modules/combat/abilities/`（施法时序与 ability 强绑定）
  - `timed_attack_action.gd` → `modules/combat/`（攻击窗口是战斗机制）
  - `dash_action.gd` → `modules/combat/`（冲刺在此项目里属于战斗能力）
  - 理由：Kernel 是任意游戏可复用的纯基础设施；这三者是具体游戏行为，"目前没有引用模块类"只是偶然，不是归属 kernel 的依据
- [x] ✅ **P0 验收**：以下命令均返回空（game_bootstrap.gd 除外）；`make demo-test` 通过；测试通过
  ```bash
  grep -rn "AbilityController\|StatsComponent\|HealthComponent\|StatusEffectController\|InventoryController" \
    addons/mkit/kernel/ --include="*.gd" | grep -v "game_bootstrap.gd"
  ```

**Phase 1 — 合并 combat/（战斗问题域）**
- [x] P1.1 `modules/stats/` → `modules/combat/stats/`
- [x] P1.2 `modules/health/` → `modules/combat/health/`
- [x] P1.3 `modules/abilities/` → `modules/combat/abilities/`
- [x] P1.4 `modules/status_effects/` → `modules/combat/status_effects/`
- [x] P1.5 更新 player.tscn / field_beast.tscn（无 uid，路径解析）及 village_rpg_content.tres 中的引用路径
- [x] P1.6 删除空目录 `stats/` `health/` `abilities/` `status_effects/`
- [x] ✅ **P1 验收**：上述 4 个目录不存在；`make ut` 221/221 通过；`make demo-test` 通过

**Phase 2 — 解耦 shop → progression**
- [x] P2.1 在 `modules/progression/` 新增 `spend_currency_effect.gd`（extends GameEffect）
  - `execute()` 必须**同步**完成余额检查与扣款，并返回对应 `EffectResult`（success / fail）
  - shop_service 依赖该返回值决定购买是否继续，不可异步延迟
- [x] P2.2 `shop_service.gd` 改为 `EffectService.execute(SpendCurrencyEffect.new(amount))`，移除 `_get_progression()` 私有方法及对 `ProgressionService` 的直接调用
  - 同时新增 `add_currency_effect.gd`（供 sell 路径用）；`_buy_block_reason` 通过 `SpendCurrencyEffect.can_spend()` 静态方法检查余额
- [x] P2.3 在 `game_bootstrap.gd` 新增 `LootSystem` 注册为 `"loot"` service（bootstrap 豁免，同其他模块 service 注册方式）
- [x] ✅ **P2 验收**：`shop_service.gd` 中无 `ProgressionService` 直接引用；shop 购买（含余额不足失败路径）测试通过；`make demo-test` 通过

**Phase 3 — 合并 world/（世界问题域）**
- [x] P3.1 `modules/room/` → `modules/world/dungeon/`
- [x] P3.2 修复两处 `RewardSystem.new()` 直接实例化：
  - `modules/world/dungeon/reward_coordinator.gd:8` → `ServiceRegistry.get_service("loot")`
  - `modules/world/dungeon/room_controller.gd:103` → 同上
- [x] P3.3 `game_bootstrap.gd` 无需更新 room 路径（class_name 全局解析）；确认 .godot 缓存刷新
- [x] P3.4 删除空目录 `modules/room/`
- [x] ✅ **P3 验收**：`modules/room/` 不存在；`grep -n "RewardSystem.new()" modules/world/dungeon/*.gd` 返回空；测试通过；`make demo-test` 通过

**Phase 4 — ~~合并 narrative/~~（已取消）**

quest/ 和 dialogue/ 保持独立模块，不合并为 narrative/。两者虽同属叙事域，但各自有独立 service 边界，合并收益有限。目标模块数调整为 12。

**Phase 5 — 文档化边界规则**
- [ ] P5.1 在 `docs/` 补充模块依赖方向规则
- [ ] P5.2 文档化 world→economy 受控 service 依赖
- [ ] P5.3 （可选）CI 加 grep 检查，拦截新的 kernel→module 违规

---

## 目标架构

### Kernel（纯基础设施）

```
kernel/
  services/            ← audio_service.gd 移入（P0.7）
  events/
  commands/
  context/
  registry/
  state_machine/
  actions/              ← builtin/ 子目录（cast/dash/timed_attack）P0.9 移出后仅剩 game_action.gd / action_service.gd 基类
  conditions/builtin/
    target_in_range_condition.gd   ← 保留（无模块依赖）
  effects/builtin/
    spawn_scene_effect.gd          ← 保留（无模块依赖）
    log_effect.gd                  ← 保留（无模块依赖）
  save/
  bootstrap/
  debug/
```

---

### modules/entity/　— 世界里存在什么？

实体的身份、生命周期与生成。

```
entity/
  entity_root.gd
  entity_identity.gd
  entity_definition.gd
  entity_spawner.gd
```

**依赖：** Kernel only

---

### modules/ai/　— 实体如何决策？

控制实体行为的 AI 层，与实体本身解耦（Controller 与 Model 分离）。

```
ai/
  brain.gd
  simple_ai_enemy_brain.gd
```

**依赖：** Kernel + `entity/`（Brain 驱动 EntityRoot 发出 Command）

---

### modules/interaction/　— 玩家如何与世界对象交互？

定义"可交互对象"协议，供 world（Portal）和 narrative（DialogueInteractable）共同实现。

```
interaction/
  interactable.gd
  interaction_component.gd
```

**依赖：** Kernel only

---

### modules/combat/　— 实体如何战斗？

一切关于战斗的数值与机制：属性、生命值、技能、状态效果、伤害结算、碰撞体。

```
combat/
  stats/
    stats_component.gd
    stat_definition.gd
    stat_modifier.gd
    stat_modifier_definition.gd
    apply_stat_modifier_effect.gd    ← P0 从 kernel/builtin 移入
  health/
    health_component.gd
    resource_pool_component.gd
    heal_effect.gd                   ← P0 从 kernel/builtin 移入
  abilities/
    ability_controller.gd
    ability_definition.gd
    ability_instance.gd
    cooldown_ready_condition.gd      ← P0 从 kernel/builtin 移入
  status_effects/
    status_effect_controller.gd
    status_effect_definition.gd
    status_effect_instance.gd
    apply_status_effect.gd           ← P0 从 kernel/builtin 移入
  damage/
    combat_service.gd
    damage_request.gd
    damage_result.gd
    hitbox_component.gd
    hurtbox_component.gd
    deal_damage_effect.gd            ← P0 从 kernel/builtin 移入
```

**依赖：** Kernel + `entity/`（hitbox/hurtbox 查找 EntityIdentity）

> Stats、Health、Abilities、StatusEffects 归入 combat 的理由：
> 这四者存在的唯一目的是让战斗计算得以进行——stats 定义数值基础，
> health 是被消耗的资源，abilities 是战斗动作，status_effects 是战斗中施加的持续效果。
> 它们是同一个问题域（"实体如何战斗"）的不同切面，合并消除了它们之间最高频的跨模块引用。

---

### modules/inventory/　— 实体携带什么？

物品的定义、持有与装备。

```
inventory/
  item_definition.gd
  item_instance.gd
  inventory_controller.gd
  inventory_model.gd
  inventory_slot.gd
  equipment_controller.gd
  grant_item_effect.gd             ← P0 从 kernel/builtin 移入
```

**依赖：** Kernel + `combat/`（equipment_controller 挂载 StatModifier 到 StatsComponent）

---

### modules/progression/　— 玩家如何成长？

经验、等级、货币与元升级。

```
progression/
  progression_service.gd
  progression_state.gd
  experience_component.gd
  experience_curve.gd
  upgrade_definition.gd
  spend_currency_effect.gd          ← P2 新增，供 shop 通过 effect 系统扣款
```

**依赖：** Kernel only

---

### modules/shop/　— 玩家如何购买？

商店交互与购买事务。

```
shop/
  shop_service.gd                   ← P2 后通过 SpendCurrencyEffect 扣款，不直接引用 ProgressionService
  shop_definition.gd
  shop_entry.gd
```

**依赖：** Kernel only（货币扣减通过 EffectService dispatch SpendCurrencyEffect，由 progression 处理）

---

### modules/loot/　— 玩家如何获得掉落？

掉落表与奖励生成。

```
loot/
  loot_system.gd                    ← 注册为 "loot" service（供 world/reward_coordinator 调用）
  loot_table_definition.gd
  loot_entry.gd
  loot_roll_result.gd
  reward_system.gd
  reward_definition.gd
  reward_option.gd
```

**依赖：** Kernel only

---

### modules/world/　— 事情发生在哪里？

宏观区域导航与地牢运行管理。

```
world/
  world_service.gd
  zone_definition.gd
  portal.gd                        ← extends entity/interaction/Interactable
  spawn_point.gd
  dungeon/                         ← 原 room/
    run_director.gd
    run_state.gd
    dungeon_generator.gd
    room_graph.gd
    room_controller.gd
    room_runtime.gd
    room_definition.gd
    room_loader.gd
    room_node.gd
    reward_coordinator.gd          ← 改为 get_service("loot")，不直接 new RewardSystem()
```

**依赖：** Kernel + `entity/`（spawn_point）+ `interaction/`（Portal extends Interactable）+ `loot` service（通过 ServiceRegistry，reward_coordinator 调用）

---

### modules/quest/　— 故事任务是什么？

```
quest/
  quest_service.gd
  quest_log.gd
  quest_state.gd
  quest_definition.gd
  quest_objective_definition.gd
  accept_quest_effect.gd
  advance_objective_effect.gd
  complete_quest_effect.gd
```

**依赖：** Kernel only

---

### modules/dialogue/　— NPC 说什么？

```
dialogue/
  dialogue_service.gd
  dialogue_runtime.gd
  dialogue_definition.gd
  dialogue_node.gd
  dialogue_choice.gd
  dialogue_interactable.gd         ← extends interaction/Interactable
```

**依赖：** Kernel + `interaction/`（DialogueInteractable extends Interactable）

---

### modules/ui/　— 玩家如何感知游戏？

界面管理与视觉反馈。

```
ui/
  ui_manager.gd
  feedback_system.gd
  damage_number_system.gd
  vfx_spawner.gd
  dialogue_ui.gd
  quest_log_ui.gd
  reward_selection_ui.gd
  shop_ui.gd
```

**依赖：** Kernel + 任意模块（单向，模块不得反向引用 ui）

---

## 依赖方向

```
                              Kernel
                                ↑
               entity      interaction      progression   loot
                 ↑               ↑               ↑
                ai        quest+dialogue  shop（effect→progression）
              combat           world（← entity + interaction + loot svc）
            inventory
                                ↑
                                ui               (← 一切)
```

**规则：**
- Kernel（game_bootstrap.gd 除外）：零模块依赖。验证：
  ```bash
  grep -rn "AbilityController\|StatsComponent\|HealthComponent\|StatusEffectController\|InventoryController" \
    addons/mkit/kernel/ --include="*.gd" | grep -v "game_bootstrap.gd"
  # 返回空即通过
  ```
- `game_bootstrap.gd` 豁免：作为组合根允许引用所有模块 service class_name
- entity / interaction / progression / loot：只依赖 Kernel，互不依赖
- ai：依赖 Kernel + entity
- combat：依赖 Kernel + entity
- inventory：依赖 Kernel + combat
- shop：只依赖 Kernel（货币扣减通过 SpendCurrencyEffect → EffectService 同步返回 EffectResult，不直接引用 progression）
- world：依赖 Kernel + entity + interaction；通过 `get_service("loot")` 调用 loot（唯一受控跨模块 service 依赖）
- quest：依赖 Kernel only
- dialogue：依赖 Kernel + `interaction/`（DialogueInteractable extends Interactable）
- ui：可引用任何层，任何层不得反向引用 ui
