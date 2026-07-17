# 计划：Cookbook 字段全覆盖（让每个 @export 字段都被用上、被解释）

> 目标：developer 读完对应 Recipe 后，知道该定义类/组件的**每一个字段**是什么意思、什么时候用、填什么值。
> 审计范围：`addons/mkit/modules/` + `addons/mkit/kernel/` 全部带 `@export` 的类（67 个），对照 `docs/cookbook/*.md`（含新增 16–20）。
> 日期：2026-06-11

## 一、现状与审计结论

用脚本逐字段比对（字段名按整词匹配任一 cookbook 文档），缺口分三类：

1. **完全没出现过的字段** — 28 个类共约 60 个字段在 15+5 篇 Recipe 里从未被提到（详见第三节分篇清单）。
2. **出现了但从不解释/永远留空** — 最典型的是各处的 `conditions = []`：`AbilityDefinition`、`ShopEntry`、`DialogueChoice`、`Interactable`、`RewardDefinition`、`LootEntry`、`QuestDefinition.accept_conditions` 全都让读者留空，但**没有任何一篇 Recipe 实际创建过一个 Condition**。整个条件系统（`Condition` 基类 + `TargetInRangeCondition` + `CooldownReadyCondition` + 自定义子类）在 cookbook 中是空白。
3. **enum 只解释了部分取值** — 如 `StatusEffectDefinition.stack_rule` 有 6 个值（`REFRESH_DURATION / ADD_STACK / REPLACE / IGNORE / EXTEND_DURATION / INDEPENDENT_STACKS`），Recipe 12 只讲了 2 个；`StatModifierDefinition.operation` 有 6 个值（`FLAT_ADD / PERCENT_ADD / PERCENT_MULTIPLY / OVERRIDE / CLAMP_MIN / CLAMP_MAX`），文档只用过 `FLAT_ADD`。

**顺带发现（需要决策，不只是补文档）：** 原有两个字段在 mkit 内部没有消费者，现已收敛：

- `AbilityDefinition.range` — 已决定删除；施放距离统一用 `conditions` + `TargetInRangeCondition.range`
- `EntityDefinition.loot_table_id` — 已决定删除；死亡掉落统一用 loot 模块的 `DeathLootRuleDefinition` + `DeathLootService`

文档无法解释「mkit 拿它做什么」。两个字段均按 API 收敛原则删除：射程判定进入 Condition；死亡掉落规则进入 loot 模块，避免 entity 模块依赖 loot 模块。

## 二、统一补齐格式

每篇 Recipe 在「步骤」之后新增一节 **`## 字段参考`**，对该篇引入的每个定义类/组件给一张全字段表：

```markdown
## 字段参考

### AbilityDefinition

| 字段 | 类型/默认 | 含义 | 什么时候改 |
|------|----------|------|-----------|
| `ability_id` | String | ContentService 注册与查询用的稳定 id | 必填，全局唯一 |
| `charges` | int = 1 | 可连续施放次数；>1 时每次 cast 扣 1 层，按 cooldown 逐层回充 | 闪避/连发类技能设 2–3 |
| ... 所有字段，一个不漏 ... |
```

规则：

1. **全字段、零遗漏**：表里列出该类全部 `@export` 字段，宁可写「预留，mkit 不读取」也不省略。
2. **enum 列全取值**：每个枚举字段在「含义」里列出所有取值和区别（一行一个）。
3. **步骤至少演示一次非默认值**：表格解释含义，步骤展示用法——每篇至少把 1–2 个之前"留空"的字段真正用起来（重点是 `conditions`）。
4. **正文已充分演示的字段**，表里一句话 + 指回步骤即可，不重复。
5. 表格放「常见错误」之前，搜索友好（字段名都是关键词）。

## 三、分篇补齐清单

按优先级排列。**缺失字段**列出含义（已从源码核实），供补写时直接使用。

### P0-1（新增）Recipe 21：条件门禁（Condition）

条件系统是横切所有模块的空白，单独成篇，其他 Recipe 链接过来：

- `Condition` 基类字段：`condition_id`（调试/trace 标识）、`invert`（取反——「不满足时才通过」）
- 内置条件演示：`TargetInRangeCondition.range`（source 到 target 距离 ≤ range）挂到技能上；`CooldownReadyCondition.ability_id`（某技能冷却就绪才允许）
- 自定义条件：继承 `Condition`，override `_evaluate(context)`（如「声望达标」「持有某物品」），呼应 Recipe 20 步骤 5
- `ConditionEvaluator.evaluate_all` 的求值时机一览表：技能 cast 前 / effect apply 前 / 对话选项显示 / 商店 entry / 交互 / 任务接取 / 掉落 entry
- 写完后：把 Recipe 05/09/14/15/17 各处 `conditions = []` 中**至少一处**改成真实演示 + 指向本篇

### P0-2 Recipe 05（技能）

| 字段 | 补什么 |
|------|--------|
| `charges` | 已列值未讲机制：>1 时可连发，逐层回充，剩余层数随存档（`current_charges`）；演示双 charge 冲刺 |
| `cost_type` / `cost_amount` | 讲清消耗的是 `ResourcePoolComponent` 的池（`"none"` 或 amount≤0 = 无消耗；池不存在时 cast 失败 `insufficient_mana`）|
| `conditions` | 演示挂 `TargetInRangeCondition`，链接 Recipe 21 |
| `icon` | UI 用图标（技能栏渲染），mkit 不读取，由 HUD 代码取用（链接 Recipe 18）|
| `description` / `tags` | 一句话：UI 文案；tags 供查询过滤 |

### P0-3 Recipe 03（血量/属性）

| 字段 | 补什么 |
|------|--------|
| `ResourcePoolComponent.starting_values` | 完全没讲：`{"mana": 50.0}` 字典定义资源池初值——它是技能 cost 的扣费来源（Recipe 05 依赖它却没人讲怎么配）|
| `StatDefinition.default_value` / `min_value` / `max_value` / `is_percent` | 属性的默认/夹取范围/百分比显示语义 |
| `StatModifierDefinition.operation` | 列全 6 个枚举值含义与计算顺序 |
| `StatModifierDefinition.priority` / `stacking_rule` / `modifier_id` | 同 stat 多 modifier 时的求值顺序与叠加规则（5 个枚举值）|
| `HealthComponent.destroy_on_death` | 死亡时是否自动释放节点（敌人 true / 玩家 false）|

### P0-4 Recipe 04（攻击动作）

| 字段 | 补什么 |
|------|--------|
| `HitboxComponent.target_factions` | 按 `EntityIdentity.faction` 过滤可命中目标（默认 `["enemy"]`——玩家打敌人；敌人的 hitbox 要改 `["player"]`）|
| `HitboxComponent.hit_once_per_activation` | 单次激活内同一目标只判一次（false = 持续伤害区）|
| `HitboxComponent.base_damage` / `element_type` / `hit_tags` / `on_hit_statuses` | 不走 effect 链时的直伤参数；元素类型进 DamageRequest；命中标签；命中附加状态（链接 Recipe 12）|
| `HurtboxComponent.owner_path` / `can_receive_damage` / `damage_multiplier` / `damage_tags` | 受击归属指定、无敌开关、部位倍率（爆头 2.0）、受击标签 |
| `DealDamageEffect.element_type` / `hit_tags` / `can_crit` | 元素与暴击参与伤害管线的哪一步（链接 pipeline.md）|

### P0-5 Recipe 12（状态效果）

| 字段 | 补什么 |
|------|--------|
| `stack_rule` | 列全 6 个枚举值（现在只讲了 `ADD_STACK` / `REFRESH_DURATION`）|
| `effects_on_apply` / `effects_on_remove` | 施加瞬间/移除瞬间的 effect 钩子（与 `effects_on_tick` 三段生命周期对比表）|
| `ApplyStatusEffect.stacks` / `duration_override` | 一次施加几层；覆盖定义时长 |

### P1-1 Recipe 08（掉落）—— 补 LootTableDefinition 整块

`RewardDefinition`（三选一奖励）讲了，但 **`LootTableDefinition` / `LootEntry`（按权重 roll 的掉落表）完全没讲**，这是 loot 模块的另一半：

| 字段 | 含义 |
|------|------|
| `LootTableDefinition.rolls` | 抽几次（每次独立 roll）|
| `LootTableDefinition.allow_empty` / `empty_weight` | 允许空手而归；「什么都不掉」作为一个权重项参与 roll |
| `LootEntry.content_id` | 掉什么（item/reward 的 content id）|
| `LootEntry.min_quantity` / `max_quantity` | 数量随机区间 |
| `LootEntry.weight` / `conditions` | 权重；满足条件才进入掉落池（链接 Recipe 21）|
| `RewardDefinition.icon` / `conditions` | 奖励图标；出现条件 |

建议加「步骤 7：敌人死亡掉落（LootTable）」演示 `LootService` 按表 roll。

### P1-2 Recipe 11（存档）

| 字段 | 含义 |
|------|------|
| `Saveable.save_scope` | 存档分组：按 scope 局部恢复（debugging.md 已提"save scope"但没讲怎么配）|
| `Saveable.restore_order` / `EntitySaveAgent.restore_order` | 恢复顺序（小的先恢复，处理依赖）|
| `EntitySaveAgent.root_path` | 显式指定收集组件的子树根（默认取 owner）|
| `EntitySaveAgent.include_duck_participants` | 是否收集 duck-typed group 成员（正文已演示 group，但开关没提）|
| `SaveService.save_version` / `schema_version` / `game_version` / `profile_id` | 存档版本头与多档位 id——版本迁移和多存档槽都靠它们 |

### P1-3 Recipe 02（玩家实体）+ Recipe 07（房间）

- `StateMachine.auto_start`（false 时手动 `start()`，给出场景：等出生动画）；`State.initial_child_state_id`（HFSM 进入复合状态时默认子状态）
- `CommandReceiver.receiver_id` / `auto_register`（跨实体按 id 路由命令时的注册名）
- `EntityDefinition.loot_table_id` — 已删除；死亡掉落在 Recipe 08 用 `DeathLootRuleDefinition` 讲解
- `RoomDefinition.difficulty_rating` / `size` / `tags`（选房算法的过滤参数，由 `RunDirector` 池逻辑/游戏代码使用）

### P2-1 Recipe 13（动画/VFX/音频）

- `AudioService.music_map` / `sfx_bus` / `music_bus` / `music_fade_floor_db`（BGM 注册表、输出总线、淡出下限）——配合 `ZoneDefinition.bgm_id`（Recipe 15）讲完整音频路径
- `SpawnSceneEffect.spawn_at_target` / `use_pool`（特效落点在 target 还是 source；走 PoolService 复用）
- `LogEffect.message` / `event_type`（调试 effect，顺手链接 debugging.md）

### P2-2 其余小补

- Recipe 01：`ResourceDatabase.resource_paths`（按路径声明资源，代替逐个拖 `resources`；两种方式对比）
- Recipe 16：`ItemDefinition.icon`（背包格子渲染用，链接 Recipe 18）
- Recipe 06：`Brain.enabled`（运行时开关 AI——剧情冻结敌人）
- Recipe 09/10：`DialogueNode.next_node_id`（无选项时直通下一节点）、`QuestDefinition.quest_type` / `repeatable` / `auto_complete` 与 `QuestObjectiveDefinition.optional` / `count_payload_key` 的语义表
- debugging.md（非 cookbook）：`DebugOverlay.watch_entity_path` / `status_provider_path` / `visible_on_start` 三个配置项现在只在代码注释里

## 四、执行顺序与工作量

| 阶段 | 内容 | 预估 |
|------|------|------|
| P0 | 新 Recipe 21（条件）+ 05/03/04/12 字段参考节 | 5 篇，每篇 0.5–1h |
| P1 | 08（LootTable 整块）+ 11 + 02/07 | 4 篇 |
| P2 | 13 + 01/06/09/10/16 小补 + debugging.md | 6 处 |
| 决策 | `EntityDefinition.loot_table_id` 已删除；补 Recipe 08 的 `DeathLootRuleDefinition` 路径 | 已并入实现 |

建议每完成一篇就跑一遍第五节脚本验证，避免回归。

## 五、验收标准与审计脚本

验收：① 脚本输出为空（每个 @export 字段至少在一篇 cookbook 出现）；② 每个 enum 字段全取值有解释；③ 每类 `conditions` 字段至少一处真实演示或链接 Recipe 21；④ 「预留字段」均有显式标注。

```bash
# tools/audit_cookbook_fields.sh —— 输出「从未在 cookbook 出现」的字段
for f in $(find addons/mkit/modules addons/mkit/kernel -name "*.gd" | sort); do
  cls=$(grep -m1 "^class_name" $f | awk '{print $2}'); [ -z "$cls" ] && continue
  exports=$(grep -oE "@export[a-z_]*(\([^)]*\))? var [a-zA-Z_]+" $f | awk '{print $NF}')
  missing=""
  for field in $exports; do
    grep -rqw "$field" docs/cookbook/*.md || missing="$missing $field"
  done
  [ -n "$missing" ] && echo "$cls:$missing"
done
```

可加为 `make cookbook-fields` 目标，跟 `make module-deps` 一样进 CI（允许白名单：预留字段标注后加入豁免表）。
