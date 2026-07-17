# mkit 内部无消费者字段扫描

范围：当前源码树的 `addons/mkit/**/*.gd`。这里的“mkit 内部消费者”指 addon 内部会读取字段并影响规则、路由、校验、事件构造、存档恢复或服务行为。`game/`、`test/`、`docs/`、生成 API HTML/XML 以及外部项目直接读取公开字段不计入内部消费者。

结论：发现一批字段在 addon 内部没有行为消费者。它们不都等价于“可以删除”：其中一部分是公共展示/调试契约，另一部分则是文档或命名暗示会参与规则，但实现没有接上。

## 高置信清理或补实现候选

| 字段 | 位置 | 当前内部消费情况 | 风险 / 建议 |
| --- | --- | --- | --- |
| `ResourceDatabase.database_id` | `addons/mkit/kernel/registry/resource_database.gd:10` | `GameBootstrap._load_content()` 只把数据库传给 `ContentService.load_database()`；`ContentService.load_database()` 只调用 `database.get_all_resources()`，没有读取 `database_id`。 | 注释写着“用于区分资源来源和校验重复配置”，但实现没有来源标记。要么在重复 id 报错里带数据库 id，要么把说明改成纯设计者备注。 |
| `DamageRequest.can_block` / `DamageResult.was_blocked` | `addons/mkit/modules/combat/damage_request.gd:24`, `addons/mkit/modules/combat/damage_result.gd:26` | `CombatService.resolve()` 读取 `can_evade`、`can_crit`，但没有读取 `can_block`，也没有任何路径把 `was_blocked` 设为 `true`。`_resolve_status_applications()` 会检查 `result.was_blocked`，但该值永远保持默认。 | 这是最像真实死逻辑的字段。若要保留 block 概念，应补格挡规则、trace、测试和文档；否则移除字段和“格挡”文案。 |
| `DamageRequest.tags` / `DamageRequest.payload` | `addons/mkit/modules/combat/damage_request.gd:26`, `addons/mkit/modules/combat/damage_request.gd:30` | `HitboxComponent`、`HurtboxComponent`、`DealDamageEffect` 会把标签写进 `request.tags`，但 `CombatService.resolve()` 不读，`DamageResult` 和 `CombatEvents.damage_applied()` 也不输出这些标签。`payload` 未见 addon 内部写入或读取。 | `hit_tags`/`damage_tags` 目前在伤害管线里断掉。要么把 tags 进入 trace/event/status context，要么把相关字段降级为预留并更新文档。 |
| `HitboxComponent.hit_tags` / `HurtboxComponent.damage_tags` / `DealDamageEffect.hit_tags` | `addons/mkit/modules/combat/hitbox_component.gd:22`, `addons/mkit/modules/combat/hurtbox_component.gd:16`, `addons/mkit/modules/combat/damage/deal_damage_effect.gd:18` | 只用于构造 `DamageRequest.tags`，而 `DamageRequest.tags` 没有下游消费者。 | 与上一项同源。当前文档说“供条件、状态和事件过滤”，实现并未做到。 |
| `StatDefinition.default_value`, `min_value`, `max_value`, `is_percent` | `addons/mkit/modules/combat/stats/stat_definition.gd:14-20` | `StatsComponent.get_stat_value()` 只读 `base_stats` 和 `modifiers_by_stat`；计算只用 `StatModifierDefinition.CLAMP_MIN/CLAMP_MAX`。没有按 `stat_id` 查 `StatDefinition`。 | 如果 `StatDefinition` 只是编辑器/UI 元信息，应在 API 注释里明确“不参与运行时计算”。若要参与运行时，应让 `StatsComponent` 从 `ContentService` 查询默认值和 clamp 元信息。 |
| `RoomDefinition.room_type`, `difficulty_rating`, `size`, `tags` | `addons/mkit/modules/world/dungeon/room_definition.gd:14-20` | `RoomLoader` 只读 `scene_path`；`RoomController` 只读 `enemy_spawn_ids` 和 `reward_pool_ids`。`DungeonGenerator.generate_linear()` 不读取 `RoomDefinition`，只从 id 池随机，并硬写 `RoomNode.room_type = "combat"`。 | 这些字段目前是自定义生成器/UI 元数据。若内置生成器要支持房间类型、难度或尺寸，应接入 `ContentService` 读取定义；否则 API 注释应避免暗示内置生成器会消费。 |
| `AbilityInstance.runtime_level`, `temporary_modifiers` | `addons/mkit/modules/combat/abilities/ability_instance.gd:18`, `addons/mkit/modules/combat/abilities/ability_instance.gd:22` | `AbilityController` 只使用 cooldown、charges、enabled、definition。等级和临时 modifier 没有读写路径。 | 保留会让使用者以为能力等级/临时强化已生效。建议补缩放/覆盖读取点，或移除/标成明确预留。 |
| `ItemDefinition.use_conditions`, `use_effects` | `addons/mkit/modules/inventory/item_definition.gd:32-34` | 背包、装备、商店和 `GrantItemEffect` 都不提供“use item”流程；addon 内没有执行这些 conditions/effects 的路径。 | 目前由 `game/village_rpg_demo.gd` 手动消费，不是 mkit 内部消费。若这是 mkit 核心契约，应加 `InventoryController.use_item()` 或 `UseItemCommand`；否则文档继续强调游戏侧接线。 |
| `UpgradeDefinition.is_meta_upgrade` | `addons/mkit/modules/progression/upgrade_definition.gd:30` | `ProgressionService.can_unlock()` / `unlock_or_level_up()` 不按该字段分支。 | 当前只是分类标记。要么接入局内/局外升级隔离，要么在 API 注释中说明 mkit 不做内置分支。 |
| `QuestDefinition.quest_type` | `addons/mkit/modules/quest/quest_definition.gd:16` | `QuestService` 不按 quest type 分支、过滤或事件输出。 | 这是 UI/分类字段，不是规则字段。建议文档明确。 |
| `EffectResult.child_results` | `addons/mkit/kernel/effects/effect_result.gd:18` | `EffectService.execute_many()` 返回数组，不构建父 `EffectResult`，也没有任何代码写入/读取 `child_results`。 | 若未来需要复合 effect，可保留；否则现在是未实现概念。 |
| `ActionContext.phase` | `addons/mkit/kernel/context/action_context.gd:12` | `CastAction` 只设置 `context.duration`；`DashAction` / `TimedAttackAction` 用 `GameAction.elapsed`，没有读写 `phase`。 | 若要表达 startup/active/recovery 阶段，应在动作实现里维护；否则是预留字段。 |
| `InventoryModel.owner_id`, `InventoryModel.capacity`, `InventorySlot.index` | `addons/mkit/modules/inventory/inventory_model.gd:10-12`, `addons/mkit/modules/inventory/inventory_slot.gd:10` | `InventoryController._ready()` 写 `model.owner_id`，`InventoryModel.setup()` 写 `capacity` 和 `slot.index`；后续事件、保存和查询都不用这些模型字段。 | 这些是冗余模型元数据。可删除，或改为让事件/保存/UI 查询从 model 读取，避免两套来源。 |
| `RewardOption.source`, `RewardOption.payload` | `addons/mkit/modules/loot/reward_option.gd:20-24` | `RewardSystem._build_option()` 没有设置，`RewardSystem.apply_selected()` 和 `RunDirector` 也不读取。 | 目前是完全未接线的扩展位。 |

## 内部无读用但可能是公共展示 / 输出契约

这些字段没有 mkit 内部规则消费者，但更像留给游戏 UI、调试、测试或外部项目直接读取的公开数据。它们不建议直接删除；建议在文档中统一标注“mkit 不内置消费”。

| 字段组 | 位置 | 说明 |
| --- | --- | --- |
| `AbilityDefinition.display_name`, `description`, `icon`, `tags` | `addons/mkit/modules/combat/abilities/ability_definition.gd:12-28` | 能力服务只读冷却、消耗、施放时间、conditions、effects。展示字段和 tags 不参与内部规则。 |
| `ItemDefinition.display_name`, `description`, `item_type`, `rarity`, `icon`, `tags` | `addons/mkit/modules/inventory/item_definition.gd:12-30` | 商店会读 `value`，背包装备会读 stack/equipment/stat fields；这些展示/分类字段不参与 addon 内部规则。 |
| `UpgradeDefinition.display_name`, `description`, `tags` | `addons/mkit/modules/progression/upgrade_definition.gd:12-28` | 进度服务只读等级、货币、成本、前置、解锁内容和 effects。 |
| `QuestDefinition.display_name`, `description`, `tags`；`QuestObjectiveDefinition.description` | `addons/mkit/modules/quest/quest_definition.gd:12-30`, `addons/mkit/modules/quest/quest_objective_definition.gd:12` | 任务服务只按 objectives、前置、条件、奖励、auto/repeatable 运行。 |
| `ZoneDefinition.display_name`, `tags` | `addons/mkit/modules/world/zone_definition.gd:12-20` | `WorldService` 只读 `scene_path`、`bgm_id`、`default_spawn_id`。 |
| `ShopDefinition.display_name` | `addons/mkit/modules/shop/shop_definition.gd:12` | `ShopService` 只读货币、entries、价格倍率、allow_sell。 |
| `StatusEffectDefinition.display_name`, `tags` | `addons/mkit/modules/combat/status_effects/status_effect_definition.gd:14-24` | 状态控制器只读 duration、tick、stack、effects、stat_modifiers。 |
| `StatDefinition.display_name` | `addons/mkit/modules/combat/stats/stat_definition.gd:12` | 纯展示元数据。 |
| `DialogueNode.speaker_id`, `text`; `DialogueChoice.text` | `addons/mkit/modules/dialogue/dialogue_node.gd:12-14`, `addons/mkit/modules/dialogue/dialogue_choice.gd:10` | `DialogueService` 只用 node id、effects、choices、conditions、next id；文本和 speaker 通过信号交给 UI。 |
| `Interactable.interaction_id`, `display_text` | `addons/mkit/modules/interaction/interactable.gd:10-12` | `InteractionComponent` 只转发 `Interactable` 对象；id/text 由 game UI 或 game logic 读取。 |
| `GameEffect.tags` | `addons/mkit/kernel/effects/game_effect.gd:14` | `GameEffect.apply()` 只读 conditions；tags 没有内置过滤。 |
| `StatModifierDefinition.tags` / `StatModifier.tags` | `addons/mkit/modules/combat/stats/stat_modifier_definition.gd:26`, `addons/mkit/modules/combat/stats/stat_modifier.gd:26` | tags 会被复制并保存，但 `StatsComponent` 不按 tags 查询或过滤。 |
| `RewardOption.display_name`, `description`, `icon`, `rarity` | `addons/mkit/modules/loot/reward_option.gd:12-18` | `RewardSystem` 会从 `RewardDefinition` 填入这些字段，但之后 mkit 只读 `reward_id` 和 `effects`。这些主要给奖励选择 UI。 |
| `LootDropResult.rule_id`, `loot_table_id`, `entity_definition_id`, `entity_ref`, `killer_ref` | `addons/mkit/modules/loot/loot_drop_result.gd:10-22` | `DeathLootService` 会写入并把整个对象塞进 `LootEvents.loot_dropped()`；mkit 内部只用 `has_content()`、事件 source/target 只读 `entity_id`/`killer_id`。 |
| `GameAction.action_id` | `addons/mkit/kernel/actions/game_action.gd:14` | `CastAction` / `DashAction` / `TimedAttackAction` 会设置，但 `ActionService` 不读取。主要是调试/外部观察。 |
| `GameCommand.command_id`, `timestamp` | `addons/mkit/kernel/commands/game_command.gd:10-18` | 创建时写入，命令接收/状态机处理只读 `command_type`、source/target、payload、consumed。 |
| `DomainEvent.event_id`, `timestamp` | `addons/mkit/kernel/events/domain_event.gd:12-14` | `EventService` 路由只按 `event_type`。这些字段用于日志/外部调试。 |
| `TimeService.elapsed_gameplay_time` | `addons/mkit/kernel/services/time_service.gd:16` | `advance()` 会累加；addon 内部没有读取，game/test 可用于观察累计 gameplay 时间。 |
| `State.owner_entity` | `addons/mkit/kernel/state_machine/state.gd:18` | `State.setup()` 写入；base `State` 不读。游戏侧继承的状态可直接读取。 |
| `StateMachine.last_transition_reason` | `addons/mkit/kernel/state_machine/state_machine.gd:28` | transition 时写入；addon 内部不读，调试文档示例会读取。 |

## 已排除的常见误报

- `Saveable.restore_order` 和 `EntitySaveAgent.restore_order`：`SaveService._restore_order()` 通过 `node.get("restore_order")` 动态读取，不能按普通 `.restore_order` grep 判断。
- `RewardDefinition.display_name/description/icon/rarity`：虽然规则不读，但 `RewardSystem._build_option()` 会复制到 `RewardOption`，不是完全无消费者。
- `GameAction.elapsed`：base class 只累加，但 `CastAction`、`DashAction`、`TimedAttackAction` 会读取它决定完成/阶段。
- `EntityDefinition.display_name/tags/default_faction/base_stats/starting_ability_ids`：`EntitySpawner` 会把它们落到实体身份、属性和能力控制器。

## 扫描方法和限制

- 第一轮用脚本抽取 `addons/mkit/**/*.gd` 的顶层成员变量，排除定义行和明显赋值行后查读用。
- 第二轮人工复核了主要服务/控制器/定义类，修正了 `size`、`tags`、`display_name` 这类常见字段名导致的假阳性/假阴性。
- 本报告不判断外部游戏项目是否读取公开字段；只判断 mkit addon 内部是否消费。
- 没有做代码修复，也没有运行 GUT；这是静态审计产物。
