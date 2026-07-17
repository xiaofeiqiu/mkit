# 字段 doc comment description 重写盘点

## 结论

`addons/mkit` 共有 **517 条字段 doc comment 是同一个生成器模板**，分布在 **113 个文件**里；全 addon 手写的字段说明只有 1 条。模板句式两种：

- `## 编辑器配置：\`X\` 表示 <类别词>，由 \`Class\` 的公开 API 读取或维护。` — 277 条，全部对应 `@export` 字段
- `## 运行时状态：\`X\` 表示 <类别词>，由 \`Class\` 的公开 API 读取或维护。` — 240 条，全部对应普通 `var`

这些 description 是占位文本，不是文档：`<类别词>` 来自按字段名猜的查表（`*_id` → "稳定 id"，`*_path` → "资源或节点路径"，猜不出来就退化成 "`Class` 的字段值"），后半句"由公开 API 读取或维护"对任何字段都成立。**全部 517 条都应视为待重写**，区别只在优先级。

根因：`tools/check_gd_doc_comments.py`（`make docs-check` 的一环）只检查 doc comment **是否存在**，不检查质量，于是历史上用生成器批量填充过关。重写后这层检查可以防丢失，但防不了再次灌水——可以考虑给 checker 加一条"禁止 `读取或维护。` 模板句"的规则防回潮。

## 反例与重写示范

`AbilityDefinition.charges` 现状：

```gdscript
## 编辑器配置：`charges` 表示 `AbilityDefinition` 的字段值，由 `AbilityDefinition` 的公开 API 读取或维护。
@export var charges: int = 1
```

读者拿到零信息。而它的真实语义（在 `ability_instance.gd` 里）是：能力的可叠加使用次数，施放消耗一发，按 `cooldown` 周期逐发回充。重写后：

```gdscript
## 能力可储存的使用次数上限。施放消耗一发，每经过一个 `cooldown` 周期回充一发；
## 设为 1（默认）即普通"放一次进一次冷却"，设为 2+ 可实现多段冲刺、多发药剂等。
@export var charges: int = 1
```

## 重写标准

一条合格的字段 description 应回答（按需取舍，通常 1–3 行）：

1. **是什么**：字段的领域含义，而不是复述字段名。
2. **单位与取值约定**：秒还是帧？0 表示禁用还是无限？负数是否合法？
3. **怎么填**：合法值范围、典型值、和编辑器里哪些资源/节点对应（尤其 id 类字段要说明 id 来自哪张表）。
4. **与其他字段的联动**：如 `cost_amount` 只在 `cost_type != "none"` 时生效。
5. **留空/默认时的行为**：默认值会发生什么。

禁止出现："表示 X 的字段值"、"由公开 API 读取或维护"、任何对所有字段都成立的句子。

## 优先级

### P0 — 内容定义资源的 `@export`（约 150 条）

设计师在 Inspector 里配表的入口，description 就是他们唯一的提示。最先重写：

- combat：`ability_definition.gd`、`status_effect_definition.gd`、`stat_definition.gd`、`stat_modifier_definition.gd`、`damage_type_definition.gd` 等
- inventory/loot/shop：`item_definition.gd`、`loot_table_definition.gd`、`loot_entry.gd`、`reward_definition.gd`、`shop_definition.gd`、`shop_entry.gd`
- quest/dialogue/progression：`quest_definition.gd`、`quest_objective_definition.gd`、`dialogue_definition.gd`、`dialogue_node.gd`、`dialogue_choice.gd`、`upgrade_definition.gd`、`experience_curve.gd`
- world/entity：`room_definition.gd`、`entity_definition.gd`
- kernel：`audio_definition.gd`、`resource_database.gd`、各 builtin effect/condition 的导出参数

重点照顾 id 类字段（89 条"稳定 id"）：必须写清 id 引用哪类资源、在哪注册；以及枚举型 String（如 `cost_type`、`stack_policy` 之类）：必须列出合法值。

### P1 — 组件/节点的 `@export`（约 120 条）

挂在场景里的组件参数：`hitbox_component.gd`、`hurtbox_component.gd`、`health_component.gd`、`stats_component.gd`、`ability_controller.gd`、`entity_spawner.gd`、`interactable.gd`、`game_bootstrap.gd`、`ui_manager.gd`、`state_machine.gd` 等。和 P0 标准相同。

### P2 — 运行时 `var`（240 条）

出现在生成的 API 文档里，但读者是写代码的人，要求可降为一句话语义（含生命周期：谁写入、何时有效）。两个额外建议：

- 其中不少字段（如 `GameAction.cancelled_flag`、`CommandReceiver.command_history`）疑似实现细节，与其写文档不如改成 `_` 私有，checker 即豁免——重写时顺手评估。
- `payload`/`Dictionary` 类字段必须写明 key 约定，否则等于没文档。

## 全量清单

以下为脚本扫描结果（517 条，按文件分组；`@export` 即 P0/P1，`var` 即 P2）。「现状」给出的是现有模板的类别词，便于评估生成器猜得离谱的程度——尤其「`Class` 的字段值」一类是零信息重灾区。

### `addons/mkit/kernel/actions/action_service.gd`

- `active_actions` (var) — 现状：运行时状态/「是否启用或当前激活状态」

### `addons/mkit/kernel/actions/game_action.gd`

- `action_id` (var) — 现状：运行时状态/「稳定 id」
- `context` (var) — 现状：运行时状态/「`GameAction` 的字段值」
- `elapsed` (var) — 现状：运行时状态/「`GameAction` 的字段值」
- `finished` (var) — 现状：运行时状态/「`GameAction` 的字段值」
- `cancelled_flag` (var) — 现状：运行时状态/「`GameAction` 的字段值」
- `cancel_tags` (var) — 现状：运行时状态/「标签集合」
- `on_start_effects` (var) — 现状：运行时状态/「效果列表」
- `on_complete_effects` (var) — 现状：运行时状态/「效果列表」
- `on_cancel_effects` (var) — 现状：运行时状态/「效果列表」

### `addons/mkit/kernel/bootstrap/game_bootstrap.gd`

- `resource_databases` (@export) — 现状：编辑器配置/「`GameBootstrap` 的字段值」
- `initial_scene_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `save_path` (@export) — 现状：编辑器配置/「资源或节点路径」

### `addons/mkit/kernel/commands/command_receiver.gd`

- `receiver_id` (@export) — 现状：编辑器配置/「稳定 id」
- `auto_register` (@export) — 现状：编辑器配置/「`CommandReceiver` 的字段值」
- `owner_entity` (var) — 现状：运行时状态/「`CommandReceiver` 的字段值」
- `state_machine` (var) — 现状：运行时状态/「运行时状态」
- `command_history` (var) — 现状：运行时状态/「`CommandReceiver` 的字段值」
- `max_history` (var) — 现状：运行时状态/「最大值」

### `addons/mkit/kernel/commands/game_command.gd`

- `command_id` (var) — 现状：运行时状态/「稳定 id」
- `command_type` (var) — 现状：运行时状态/「`GameCommand` 的字段值」
- `source_id` (var) — 现状：运行时状态/「稳定 id」
- `target_id` (var) — 现状：运行时状态/「稳定 id」
- `timestamp` (var) — 现状：运行时状态/「`GameCommand` 的字段值」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」
- `consumed` (var) — 现状：运行时状态/「`GameCommand` 的字段值」

### `addons/mkit/kernel/conditions/builtin/target_in_range_condition.gd`

- `range` (@export) — 现状：编辑器配置/「距离或范围」

### `addons/mkit/kernel/conditions/condition.gd`

- `condition_id` (@export) — 现状：编辑器配置/「稳定 id」
- `invert` (@export) — 现状：编辑器配置/「`Condition` 的字段值」

### `addons/mkit/kernel/context/action_context.gd`

- `duration` (var) — 现状：运行时状态/「持续时间」
- `phase` (var) — 现状：运行时状态/「`ActionContext` 的字段值」

### `addons/mkit/kernel/context/gameplay_context.gd`

- `source` (var) — 现状：运行时状态/「`GameplayContext` 的字段值」
- `target` (var) — 现状：运行时状态/「`GameplayContext` 的字段值」
- `instigator` (var) — 现状：运行时状态/「`GameplayContext` 的字段值」
- `position` (var) — 现状：运行时状态/「`GameplayContext` 的字段值」
- `direction` (var) — 现状：运行时状态/「`GameplayContext` 的字段值」
- `tags` (var) — 现状：运行时状态/「标签集合」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」

### `addons/mkit/kernel/debug/debug_overlay.gd`

- `watch_entity_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `status_provider_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `visible_on_start` (@export) — 现状：编辑器配置/「`DebugOverlay` 的字段值」
- `show_registered_services` (@export) — 现状：编辑器配置/「`DebugOverlay` 的字段值」

### `addons/mkit/kernel/effects/builtin/log_effect.gd`

- `message` (@export) — 现状：编辑器配置/「`LogEffect` 的字段值」
- `event_type` (@export) — 现状：编辑器配置/「`LogEffect` 的字段值」

### `addons/mkit/kernel/effects/builtin/spawn_scene_effect.gd`

- `scene_path` (@export) — 现状：编辑器配置/「场景路径」
- `spawn_at_target` (@export) — 现状：编辑器配置/「`SpawnSceneEffect` 的字段值」
- `use_pool` (@export) — 现状：编辑器配置/「`SpawnSceneEffect` 的字段值」

### `addons/mkit/kernel/effects/effect_result.gd`

- `success` (var) — 现状：运行时状态/「`EffectResult` 的字段值」
- `effect_id` (var) — 现状：运行时状态/「稳定 id」
- `failure_reason` (var) — 现状：运行时状态/「`EffectResult` 的字段值」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」
- `child_results` (var) — 现状：运行时状态/「执行结果集合」

### `addons/mkit/kernel/effects/effect_service.gd`

- `recent_results` (var) — 现状：运行时状态/「执行结果集合」
- `max_recent_results` (var) — 现状：运行时状态/「执行结果集合」

### `addons/mkit/kernel/effects/game_effect.gd`

- `effect_id` (@export) — 现状：编辑器配置/「稳定 id」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `tags` (@export) — 现状：编辑器配置/「标签集合」

### `addons/mkit/kernel/entity/entity_identity.gd`

- `entity_id` (@export) — 现状：编辑器配置/「稳定 id」
- `definition_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `faction` (@export) — 现状：编辑器配置/「`EntityIdentity` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」

### `addons/mkit/kernel/entity/entity_root.gd`

- `identity` (var) — 现状：运行时状态/「`EntityRoot` 的字段值」
- `state_machine` (var) — 现状：运行时状态/「运行时状态」
- `command_receiver` (var) — 现状：运行时状态/「`EntityRoot` 的字段值」

### `addons/mkit/kernel/events/domain_event.gd`

- `event_type` (var) — 现状：运行时状态/「`DomainEvent` 的字段值」
- `event_id` (var) — 现状：运行时状态/「稳定 id」
- `timestamp` (var) — 现状：运行时状态/「`DomainEvent` 的字段值」
- `source_id` (var) — 现状：运行时状态/「稳定 id」
- `target_id` (var) — 现状：运行时状态/「稳定 id」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」

### `addons/mkit/kernel/events/event_service.gd`

- `recent_events` (var) — 现状：运行时状态/「`EventService` 的字段值」
- `max_recent_events` (var) — 现状：运行时状态/「最大值」

### `addons/mkit/kernel/registry/content_validation_result.gd`

- `success` (var) — 现状：运行时状态/「`ContentValidationResult` 的字段值」
- `errors` (var) — 现状：运行时状态/「`ContentValidationResult` 的字段值」
- `warnings` (var) — 现状：运行时状态/「`ContentValidationResult` 的字段值」

### `addons/mkit/kernel/registry/resource_database.gd`

- `database_id` (@export) — 现状：编辑器配置/「稳定 id」
- `resources` (@export) — 现状：编辑器配置/「`ResourceDatabase` 的字段值」
- `resource_paths` (@export) — 现状：编辑器配置/「资源或节点路径列表」

### `addons/mkit/kernel/save/entity_save_agent.gd`

- `entity_id` (@export) — 现状：编辑器配置/「稳定 id」
- `scene_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `zone_id` (@export) — 现状：编辑器配置/「稳定 id」
- `root_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `restore_order` (@export) — 现状：编辑器配置/「`EntitySaveAgent` 的字段值」
- `include_duck_participants` (@export) — 现状：编辑器配置/「`EntitySaveAgent` 的字段值」

### `addons/mkit/kernel/save/save_service.gd`

- `save_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `save_version` (@export) — 现状：编辑器配置/「`SaveService` 的字段值」
- `schema_version` (@export) — 现状：编辑器配置/「`SaveService` 的字段值」
- `game_version` (@export) — 现状：编辑器配置/「`SaveService` 的字段值」
- `profile_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/kernel/save/saveable.gd`

- `save_id` (@export) — 现状：编辑器配置/「稳定 id」
- `save_scope` (@export) — 现状：编辑器配置/「`Saveable` 的字段值」
- `restore_order` (@export) — 现状：编辑器配置/「`Saveable` 的字段值」

### `addons/mkit/kernel/services/audio_definition.gd`

- `audio_id` (@export) — 现状：编辑器配置/「稳定 id」
- `stream` (@export) — 现状：编辑器配置/「`AudioDefinition` 的字段值」
- `kind` (@export) — 现状：编辑器配置/「`AudioDefinition` 的字段值」
- `loop` (@export) — 现状：编辑器配置/「`AudioDefinition` 的字段值」

### `addons/mkit/kernel/services/audio_service.gd`

- `sfx_map` (@export) — 现状：编辑器配置/「`AudioService` 的字段值」
- `music_map` (@export) — 现状：编辑器配置/「`AudioService` 的字段值」
- `sfx_bus` (@export) — 现状：编辑器配置/「`AudioService` 的字段值」
- `music_bus` (@export) — 现状：编辑器配置/「`AudioService` 的字段值」
- `music_fade_floor_db` (@export) — 现状：编辑器配置/「`AudioService` 的字段值」
- `music_player` (var) — 现状：运行时状态/「`AudioService` 的字段值」
- `current_music_id` (var) — 现状：运行时状态/「稳定 id」
- `bus_volumes` (var) — 现状：运行时状态/「`AudioService` 的字段值」

### `addons/mkit/kernel/services/random_service.gd`

- `seed_value` (var) — 现状：运行时状态/「`RandomService` 的字段值」
- `rng` (var) — 现状：运行时状态/「`RandomService` 的字段值」

### `addons/mkit/kernel/services/scene_service.gd`

- `current_scene_path` (var) — 现状：运行时状态/「资源或节点路径」
- `transition_locked` (var) — 现状：运行时状态/「`SceneService` 的字段值」

### `addons/mkit/kernel/services/time_service.gd`

- `paused` (var) — 现状：运行时状态/「`TimeService` 的字段值」
- `gameplay_time_scale` (var) — 现状：运行时状态/「`TimeService` 的字段值」
- `elapsed_gameplay_time` (var) — 现状：运行时状态/「`TimeService` 的字段值」

### `addons/mkit/kernel/state_machine/state.gd`

- `state_id` (@export) — 现状：编辑器配置/「稳定 id」
- `initial_child_state_id` (@export) — 现状：编辑器配置/「稳定 id」
- `parent_state` (var) — 现状：运行时状态/「运行时状态」
- `state_machine` (var) — 现状：运行时状态/「运行时状态」
- `owner_entity` (var) — 现状：运行时状态/「`State` 的字段值」
- `active_child` (var) — 现状：运行时状态/「是否启用或当前激活状态」
- `blackboard` (var) — 现状：运行时状态/「`State` 的字段值」

### `addons/mkit/kernel/state_machine/state_machine.gd`

- `initial_state_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `auto_start` (@export) — 现状：编辑器配置/「`StateMachine` 的字段值」
- `owner_entity` (var) — 现状：运行时状态/「`StateMachine` 的字段值」
- `root_state` (var) — 现状：运行时状态/「运行时状态」
- `current_leaf_state` (var) — 现状：运行时状态/「运行时状态」
- `blackboard` (var) — 现状：运行时状态/「`StateMachine` 的字段值」
- `previous_path` (var) — 现状：运行时状态/「资源或节点路径」
- `last_transition_reason` (var) — 现状：运行时状态/「`StateMachine` 的字段值」
- `last_failed_transition_reason` (var) — 现状：运行时状态/「`StateMachine` 的字段值」

### `addons/mkit/modules/ai/brain.gd`

- `enabled` (@export) — 现状：编辑器配置/「是否启用」
- `think_interval` (@export) — 现状：编辑器配置/「时间间隔」
- `command_receiver` (var) — 现状：运行时状态/「`Brain` 的字段值」
- `target` (var) — 现状：运行时状态/「`Brain` 的字段值」
- `blackboard` (var) — 现状：运行时状态/「`Brain` 的字段值」

### `addons/mkit/modules/ai/simple_ai_enemy_brain.gd`

- `detection_range` (@export) — 现状：编辑器配置/「距离或范围」
- `attack_range` (@export) — 现状：编辑器配置/「距离或范围」
- `target_group` (@export) — 现状：编辑器配置/「`SimpleAIEnemyBrain` 的字段值」

### `addons/mkit/modules/combat/abilities/ability_controller.gd`

- `starting_ability_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `abilities` (var) — 现状：运行时状态/「`AbilityController` 的字段值」
- `active_cast_actions` (var) — 现状：运行时状态/「是否启用或当前激活状态」

### `addons/mkit/modules/combat/abilities/ability_definition.gd`

- `ability_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `icon` (@export) — 现状：编辑器配置/「`AbilityDefinition` 的字段值」
- `cooldown` (@export) — 现状：编辑器配置/「冷却时间」
- `charges` (@export) — 现状：编辑器配置/「`AbilityDefinition` 的字段值」
- `cost_type` (@export) — 现状：编辑器配置/「消耗配置」
- `cost_amount` (@export) — 现状：编辑器配置/「数量值」
- `cast_time` (@export) — 现状：编辑器配置/「`AbilityDefinition` 的字段值」
- `range` (@export) — 现状：编辑器配置/「距离或范围」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `effects` (@export) — 现状：编辑器配置/「效果列表」

### `addons/mkit/modules/combat/abilities/ability_instance.gd`

- `definition_id` (var) — 现状：运行时状态/「稳定 id」
- `owner` (var) — 现状：运行时状态/「`AbilityInstance` 的字段值」
- `cooldown_remaining` (var) — 现状：运行时状态/「冷却时间」
- `current_charges` (var) — 现状：运行时状态/「当前值」
- `runtime_level` (var) — 现状：运行时状态/「运行时数据」
- `enabled` (var) — 现状：运行时状态/「是否启用」
- `temporary_modifiers` (var) — 现状：运行时状态/「`AbilityInstance` 的字段值」

### `addons/mkit/modules/combat/abilities/cast_action.gd`

- `duration` (var) — 现状：运行时状态/「持续时间」
- `animation_name` (var) — 现状：运行时状态/「`CastAction` 的字段值」

### `addons/mkit/modules/combat/abilities/cooldown_ready_condition.gd`

- `ability_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/combat/actions/dash_action.gd`

- `duration` (var) — 现状：运行时状态/「持续时间」
- `speed` (var) — 现状：运行时状态/「`DashAction` 的字段值」
- `direction` (var) — 现状：运行时状态/「`DashAction` 的字段值」

### `addons/mkit/modules/combat/actions/timed_attack_action.gd`

- `startup_duration` (var) — 现状：运行时状态/「持续时间」
- `active_duration` (var) — 现状：运行时状态/「是否启用或当前激活状态」
- `recovery_duration` (var) — 现状：运行时状态/「持续时间」
- `hitbox_component_name` (var) — 现状：运行时状态/「`TimedAttackAction` 的字段值」
- `hitbox_path` (var) — 现状：运行时状态/「资源或节点路径」

### `addons/mkit/modules/combat/damage/deal_damage_effect.gd`

- `base_amount` (@export) — 现状：编辑器配置/「数量值」
- `damage_type` (@export) — 现状：编辑器配置/「`DealDamageEffect` 的字段值」
- `element_type` (@export) — 现状：编辑器配置/「`DealDamageEffect` 的字段值」
- `can_crit` (@export) — 现状：编辑器配置/「`DealDamageEffect` 的字段值」
- `hit_tags` (@export) — 现状：编辑器配置/「标签集合」
- `on_hit_statuses` (@export) — 现状：编辑器配置/「`DealDamageEffect` 的字段值」

### `addons/mkit/modules/combat/damage_request.gd`

- `source` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `target` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `base_amount` (var) — 现状：运行时状态/「数量值」
- `damage_type` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `element_type` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `can_crit` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `can_evade` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `can_block` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `tags` (var) — 现状：运行时状态/「标签集合」
- `on_hit_statuses` (var) — 现状：运行时状态/「`DamageRequest` 的字段值」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」

### `addons/mkit/modules/combat/damage_result.gd`

- `source` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `target` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `base_amount` (var) — 现状：运行时状态/「数量值」
- `final_amount` (var) — 现状：运行时状态/「数量值」
- `damage_type` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `element_type` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `was_critical` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `was_evaded` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `was_blocked` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `was_lethal` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `applied_status_effects` (var) — 现状：运行时状态/「效果列表」
- `status_applications` (var) — 现状：运行时状态/「`DamageResult` 的字段值」
- `trace` (var) — 现状：运行时状态/「`DamageResult` 的字段值」

### `addons/mkit/modules/combat/health/heal_effect.gd`

- `base_amount` (@export) — 现状：编辑器配置/「数量值」

### `addons/mkit/modules/combat/health/health_component.gd`

- `current_hp` (@export) — 现状：编辑器配置/「当前值」
- `destroy_on_death` (@export) — 现状：编辑器配置/「`HealthComponent` 的字段值」
- `dead` (var) — 现状：运行时状态/「`HealthComponent` 的字段值」
- `stats` (var) — 现状：运行时状态/「`HealthComponent` 的字段值」

### `addons/mkit/modules/combat/health/resource_pool_component.gd`

- `starting_values` (@export) — 现状：编辑器配置/「`ResourcePoolComponent` 的字段值」
- `resources` (var) — 现状：运行时状态/「`ResourcePoolComponent` 的字段值」
- `stats` (var) — 现状：运行时状态/「`ResourcePoolComponent` 的字段值」

### `addons/mkit/modules/combat/hitbox_component.gd`

- `active` (@export) — 现状：编辑器配置/「是否启用或当前激活状态」
- `base_damage` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `damage_type` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `element_type` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `hit_once_per_activation` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `target_factions` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `hit_tags` (@export) — 现状：编辑器配置/「标签集合」
- `on_hit_statuses` (@export) — 现状：编辑器配置/「`HitboxComponent` 的字段值」
- `source_entity` (var) — 现状：运行时状态/「`HitboxComponent` 的字段值」
- `already_hit` (var) — 现状：运行时状态/「`HitboxComponent` 的字段值」

### `addons/mkit/modules/combat/hurtbox_component.gd`

- `owner_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `can_receive_damage` (@export) — 现状：编辑器配置/「`HurtboxComponent` 的字段值」
- `damage_multiplier` (@export) — 现状：编辑器配置/「`HurtboxComponent` 的字段值」
- `damage_tags` (@export) — 现状：编辑器配置/「标签集合」

### `addons/mkit/modules/combat/resource_set.gd`

- `current` (var) — 现状：运行时状态/「当前值」
- `max_value_provider` (var) — 现状：运行时状态/「最大值」

### `addons/mkit/modules/combat/stats/apply_stat_modifier_effect.gd`

- `stat_id` (@export) — 现状：编辑器配置/「稳定 id」
- `operation` (@export) — 现状：编辑器配置/「`ApplyStatModifierEffect` 的字段值」
- `value` (@export) — 现状：编辑器配置/「`ApplyStatModifierEffect` 的字段值」
- `duration` (@export) — 现状：编辑器配置/「持续时间」
- `stacking_rule` (@export) — 现状：编辑器配置/「`ApplyStatModifierEffect` 的字段值」
- `apply_to_source` (@export) — 现状：编辑器配置/「`ApplyStatModifierEffect` 的字段值」

### `addons/mkit/modules/combat/stats/stat_definition.gd`

- `stat_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `default_value` (@export) — 现状：编辑器配置/「`StatDefinition` 的字段值」
- `min_value` (@export) — 现状：编辑器配置/「最小值」
- `max_value` (@export) — 现状：编辑器配置/「最大值」
- `is_percent` (@export) — 现状：编辑器配置/「`StatDefinition` 的字段值」

### `addons/mkit/modules/combat/stats/stat_modifier.gd`

- `modifier_id` (var) — 现状：运行时状态/「稳定 id」
- `stat_id` (var) — 现状：运行时状态/「稳定 id」
- `source_id` (var) — 现状：运行时状态/「稳定 id」
- `operation` (var) — 现状：运行时状态/「`StatModifier` 的字段值」
- `value` (var) — 现状：运行时状态/「`StatModifier` 的字段值」
- `priority` (var) — 现状：运行时状态/「`StatModifier` 的字段值」
- `stacking_rule` (var) — 现状：运行时状态/「`StatModifier` 的字段值」
- `remaining_duration` (var) — 现状：运行时状态/「持续时间」
- `tags` (var) — 现状：运行时状态/「标签集合」

### `addons/mkit/modules/combat/stats/stat_modifier_definition.gd`

- `modifier_id` (@export) — 现状：编辑器配置/「稳定 id」
- `stat_id` (@export) — 现状：编辑器配置/「稳定 id」
- `operation` (@export) — 现状：编辑器配置/「`StatModifierDefinition` 的字段值」
- `value` (@export) — 现状：编辑器配置/「`StatModifierDefinition` 的字段值」
- `priority` (@export) — 现状：编辑器配置/「`StatModifierDefinition` 的字段值」
- `stacking_rule` (@export) — 现状：编辑器配置/「`StatModifierDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」

### `addons/mkit/modules/combat/stats/stats_component.gd`

- `base_stats` (@export) — 现状：编辑器配置/「`StatsComponent` 的字段值」
- `modifiers_by_stat` (var) — 现状：运行时状态/「`StatsComponent` 的字段值」
- `cached_values` (var) — 现状：运行时状态/「`StatsComponent` 的字段值」
- `dirty_stats` (var) — 现状：运行时状态/「`StatsComponent` 的字段值」

### `addons/mkit/modules/combat/status_effects/apply_status_effect.gd`

- `status_id` (@export) — 现状：编辑器配置/「稳定 id」
- `stacks` (@export) — 现状：编辑器配置/「`ApplyStatusEffect` 的字段值」
- `duration_override` (@export) — 现状：编辑器配置/「持续时间」

### `addons/mkit/modules/combat/status_effects/status_effect_controller.gd`

- `active_statuses` (var) — 现状：运行时状态/「是否启用或当前激活状态」

### `addons/mkit/modules/combat/status_effects/status_effect_definition.gd`

- `status_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `duration` (@export) — 现状：编辑器配置/「持续时间」
- `tick_interval` (@export) — 现状：编辑器配置/「时间间隔」
- `max_stacks` (@export) — 现状：编辑器配置/「最大值」
- `stack_rule` (@export) — 现状：编辑器配置/「`StatusEffectDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `effects_on_apply` (@export) — 现状：编辑器配置/「效果列表」
- `effects_on_tick` (@export) — 现状：编辑器配置/「效果列表」
- `effects_on_remove` (@export) — 现状：编辑器配置/「效果列表」
- `stat_modifiers` (@export) — 现状：编辑器配置/「`StatusEffectDefinition` 的字段值」

### `addons/mkit/modules/combat/status_effects/status_effect_instance.gd`

- `instance_id` (var) — 现状：运行时状态/「稳定 id」
- `definition_id` (var) — 现状：运行时状态/「稳定 id」
- `source_id` (var) — 现状：运行时状态/「稳定 id」
- `source` (var) — 现状：运行时状态/「`StatusEffectInstance` 的字段值」
- `target` (var) — 现状：运行时状态/「`StatusEffectInstance` 的字段值」
- `remaining_duration` (var) — 现状：运行时状态/「持续时间」
- `tick_timer` (var) — 现状：运行时状态/「`StatusEffectInstance` 的字段值」
- `stacks` (var) — 现状：运行时状态/「`StatusEffectInstance` 的字段值」
- `applied_modifier_ids` (var) — 现状：运行时状态/「稳定 id 列表」

### `addons/mkit/modules/dialogue/dialogue_choice.gd`

- `text` (@export) — 现状：编辑器配置/「`DialogueChoice` 的字段值」
- `next_node_id` (@export) — 现状：编辑器配置/「稳定 id」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `effects` (@export) — 现状：编辑器配置/「效果列表」

### `addons/mkit/modules/dialogue/dialogue_definition.gd`

- `dialogue_id` (@export) — 现状：编辑器配置/「稳定 id」
- `start_node_id` (@export) — 现状：编辑器配置/「稳定 id」
- `nodes` (@export) — 现状：编辑器配置/「`DialogueDefinition` 的字段值」

### `addons/mkit/modules/dialogue/dialogue_interactable.gd`

- `dialogue_id` (@export) — 现状：编辑器配置/「稳定 id」
- `npc_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/dialogue/dialogue_node.gd`

- `node_id` (@export) — 现状：编辑器配置/「稳定 id」
- `speaker_id` (@export) — 现状：编辑器配置/「稳定 id」
- `text` (@export) — 现状：编辑器配置/「`DialogueNode` 的字段值」
- `on_enter_effects` (@export) — 现状：编辑器配置/「效果列表」
- `choices` (@export) — 现状：编辑器配置/「`DialogueNode` 的字段值」
- `next_node_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/dialogue/dialogue_runtime.gd`

- `dialogue_id` (var) — 现状：运行时状态/「稳定 id」
- `current_node_id` (var) — 现状：运行时状态/「稳定 id」
- `history` (var) — 现状：运行时状态/「`DialogueRuntime` 的字段值」
- `context` (var) — 现状：运行时状态/「`DialogueRuntime` 的字段值」

### `addons/mkit/modules/dialogue/dialogue_service.gd`

- `runtime` (var) — 现状：运行时状态/「运行时数据」

### `addons/mkit/modules/entity/entity_definition.gd`

- `entity_definition_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `scene_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `default_faction` (@export) — 现状：编辑器配置/「`EntityDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `base_stats` (@export) — 现状：编辑器配置/「`EntityDefinition` 的字段值」
- `starting_ability_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `loot_table_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/entity/entity_spawner.gd`

- `content` (var) — 现状：运行时状态/「`EntitySpawner` 的字段值」

### `addons/mkit/modules/interaction/interactable.gd`

- `interaction_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_text` (@export) — 现状：编辑器配置/「`Interactable` 的字段值」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」

### `addons/mkit/modules/interaction/interaction_component.gd`

- `current_interactable` (var) — 现状：运行时状态/「当前值」

### `addons/mkit/modules/inventory/equipment_controller.gd`

- `allowed_slots` (@export) — 现状：编辑器配置/「`EquipmentController` 的字段值」
- `equipped` (var) — 现状：运行时状态/「`EquipmentController` 的字段值」

### `addons/mkit/modules/inventory/grant_item_effect.gd`

- `item_id` (@export) — 现状：编辑器配置/「稳定 id」
- `quantity` (@export) — 现状：编辑器配置/「`GrantItemEffect` 的字段值」
- `give_to_source` (@export) — 现状：编辑器配置/「`GrantItemEffect` 的字段值」

### `addons/mkit/modules/inventory/inventory_controller.gd`

- `capacity` (@export) — 现状：编辑器配置/「`InventoryController` 的字段值」
- `model` (var) — 现状：运行时状态/「`InventoryController` 的字段值」

### `addons/mkit/modules/inventory/inventory_model.gd`

- `owner_id` (var) — 现状：运行时状态/「稳定 id」
- `capacity` (var) — 现状：运行时状态/「`InventoryModel` 的字段值」
- `slots` (var) — 现状：运行时状态/「`InventoryModel` 的字段值」

### `addons/mkit/modules/inventory/inventory_slot.gd`

- `index` (var) — 现状：运行时状态/「`InventorySlot` 的字段值」
- `item` (var) — 现状：运行时状态/「`InventorySlot` 的字段值」

### `addons/mkit/modules/inventory/item_definition.gd`

- `item_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `item_type` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `rarity` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `value` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `icon` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `stackable` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `max_stack` (@export) — 现状：编辑器配置/「最大值」
- `equipment_slot` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `use_conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `use_effects` (@export) — 现状：编辑器配置/「效果列表」
- `stat_modifiers` (@export) — 现状：编辑器配置/「`ItemDefinition` 的字段值」

### `addons/mkit/modules/inventory/item_instance.gd`

- `instance_id` (var) — 现状：运行时状态/「稳定 id」
- `definition_id` (var) — 现状：运行时状态/「稳定 id」
- `quantity` (var) — 现状：运行时状态/「`ItemInstance` 的字段值」
- `rolled_affixes` (var) — 现状：运行时状态/「`ItemInstance` 的字段值」
- `durability` (var) — 现状：运行时状态/「`ItemInstance` 的字段值」
- `upgrade_level` (var) — 现状：运行时状态/「`ItemInstance` 的字段值」
- `metadata` (var) — 现状：运行时状态/「`ItemInstance` 的字段值」

### `addons/mkit/modules/loot/loot_entry.gd`

- `content_id` (@export) — 现状：编辑器配置/「稳定 id」
- `weight` (@export) — 现状：编辑器配置/「`LootEntry` 的字段值」
- `min_quantity` (@export) — 现状：编辑器配置/「最小值」
- `max_quantity` (@export) — 现状：编辑器配置/「最大值」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」

### `addons/mkit/modules/loot/loot_roll_result.gd`

- `item_instances` (var) — 现状：运行时状态/「`LootRollResult` 的字段值」
- `currency` (var) — 现状：运行时状态/「`LootRollResult` 的字段值」
- `debug_rolls` (var) — 现状：运行时状态/「`LootRollResult` 的字段值」

### `addons/mkit/modules/loot/loot_table_definition.gd`

- `loot_table_id` (@export) — 现状：编辑器配置/「稳定 id」
- `rolls` (@export) — 现状：编辑器配置/「`LootTableDefinition` 的字段值」
- `entries` (@export) — 现状：编辑器配置/「`LootTableDefinition` 的字段值」
- `allow_empty` (@export) — 现状：编辑器配置/「`LootTableDefinition` 的字段值」
- `empty_weight` (@export) — 现状：编辑器配置/「`LootTableDefinition` 的字段值」

### `addons/mkit/modules/loot/reward_definition.gd`

- `reward_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `icon` (@export) — 现状：编辑器配置/「`RewardDefinition` 的字段值」
- `rarity` (@export) — 现状：编辑器配置/「`RewardDefinition` 的字段值」
- `weight` (@export) — 现状：编辑器配置/「`RewardDefinition` 的字段值」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `effects` (@export) — 现状：编辑器配置/「效果列表」

### `addons/mkit/modules/loot/reward_option.gd`

- `reward_id` (var) — 现状：运行时状态/「稳定 id」
- `display_name` (var) — 现状：运行时状态/「面向玩家或编辑器的显示名」
- `description` (var) — 现状：运行时状态/「说明文本」
- `icon` (var) — 现状：运行时状态/「`RewardOption` 的字段值」
- `rarity` (var) — 现状：运行时状态/「`RewardOption` 的字段值」
- `source` (var) — 现状：运行时状态/「`RewardOption` 的字段值」
- `effects` (var) — 现状：运行时状态/「效果列表」
- `payload` (var) — 现状：运行时状态/「事件或存档载荷」

### `addons/mkit/modules/progression/add_currency_effect.gd`

- `currency_id` (var) — 现状：运行时状态/「稳定 id」
- `amount` (var) — 现状：运行时状态/「数量值」

### `addons/mkit/modules/progression/experience_component.gd`

- `curve` (@export) — 现状：编辑器配置/「`ExperienceComponent` 的字段值」
- `starting_level` (@export) — 现状：编辑器配置/「`ExperienceComponent` 的字段值」
- `current_level` (var) — 现状：运行时状态/「当前值」
- `current_xp` (var) — 现状：运行时状态/「当前值」

### `addons/mkit/modules/progression/experience_curve.gd`

- `max_level` (@export) — 现状：编辑器配置/「最大值」
- `xp_thresholds` (@export) — 现状：编辑器配置/「`ExperienceCurve` 的字段值」
- `base_xp` (@export) — 现状：编辑器配置/「`ExperienceCurve` 的字段值」
- `growth_factor` (@export) — 现状：编辑器配置/「`ExperienceCurve` 的字段值」

### `addons/mkit/modules/progression/progression_service.gd`

- `state` (var) — 现状：运行时状态/「运行时状态」

### `addons/mkit/modules/progression/progression_state.gd`

- `wallet` (var) — 现状：运行时状态/「`ProgressionState` 的字段值」
- `upgrade_levels` (var) — 现状：运行时状态/「`ProgressionState` 的字段值」
- `unlocked_content_ids` (var) — 现状：运行时状态/「稳定 id 列表」

### `addons/mkit/modules/progression/spend_currency_effect.gd`

- `currency_id` (var) — 现状：运行时状态/「稳定 id」
- `amount` (var) — 现状：运行时状态/「数量值」

### `addons/mkit/modules/progression/upgrade_definition.gd`

- `upgrade_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `max_level` (@export) — 现状：编辑器配置/「最大值」
- `currency_id` (@export) — 现状：编辑器配置/「稳定 id」
- `cost_by_level` (@export) — 现状：编辑器配置/「消耗配置」
- `prerequisite_upgrade_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `unlock_content_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `effects` (@export) — 现状：编辑器配置/「效果列表」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `is_meta_upgrade` (@export) — 现状：编辑器配置/「`UpgradeDefinition` 的字段值」

### `addons/mkit/modules/progression/wallet.gd`

- `balances` (var) — 现状：运行时状态/「`Wallet` 的字段值」

### `addons/mkit/modules/quest/accept_quest_effect.gd`

- `quest_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/quest/advance_objective_effect.gd`

- `quest_id` (@export) — 现状：编辑器配置/「稳定 id」
- `objective_id` (@export) — 现状：编辑器配置/「稳定 id」
- `amount` (@export) — 现状：编辑器配置/「数量值」

### `addons/mkit/modules/quest/complete_quest_effect.gd`

- `quest_id` (@export) — 现状：编辑器配置/「稳定 id」
- `turn_in` (@export) — 现状：编辑器配置/「`CompleteQuestEffect` 的字段值」

### `addons/mkit/modules/quest/quest_definition.gd`

- `quest_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `quest_type` (@export) — 现状：编辑器配置/「`QuestDefinition` 的字段值」
- `objectives` (@export) — 现状：编辑器配置/「`QuestDefinition` 的字段值」
- `prerequisite_quest_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `accept_conditions` (@export) — 现状：编辑器配置/「执行条件列表」
- `reward_effects` (@export) — 现状：编辑器配置/「效果列表」
- `auto_complete` (@export) — 现状：编辑器配置/「`QuestDefinition` 的字段值」
- `repeatable` (@export) — 现状：编辑器配置/「`QuestDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」

### `addons/mkit/modules/quest/quest_log.gd`

- `states` (var) — 现状：运行时状态/「`QuestLog` 的字段值」

### `addons/mkit/modules/quest/quest_objective_definition.gd`

- `objective_id` (@export) — 现状：编辑器配置/「稳定 id」
- `description` (@export) — 现状：编辑器配置/「说明文本」
- `event_type` (@export) — 现状：编辑器配置/「`QuestObjectiveDefinition` 的字段值」
- `match_key` (@export) — 现状：编辑器配置/「`QuestObjectiveDefinition` 的字段值」
- `match_value` (@export) — 现状：编辑器配置/「`QuestObjectiveDefinition` 的字段值」
- `count_payload_key` (@export) — 现状：编辑器配置/「事件或存档载荷」
- `required_count` (@export) — 现状：编辑器配置/「数量上限或计数」
- `optional` (@export) — 现状：编辑器配置/「`QuestObjectiveDefinition` 的字段值」

### `addons/mkit/modules/quest/quest_service.gd`

- `log` (var) — 现状：运行时状态/「`QuestService` 的字段值」

### `addons/mkit/modules/quest/quest_state.gd`

- `quest_id` (var) — 现状：运行时状态/「稳定 id」
- `status` (var) — 现状：运行时状态/「`QuestState` 的字段值」
- `objective_progress` (var) — 现状：运行时状态/「`QuestState` 的字段值」

### `addons/mkit/modules/shop/shop_definition.gd`

- `shop_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `currency_id` (@export) — 现状：编辑器配置/「稳定 id」
- `entries` (@export) — 现状：编辑器配置/「`ShopDefinition` 的字段值」
- `buy_price_multiplier` (@export) — 现状：编辑器配置/「价格配置」
- `sell_price_multiplier` (@export) — 现状：编辑器配置/「价格配置」
- `allow_sell` (@export) — 现状：编辑器配置/「`ShopDefinition` 的字段值」

### `addons/mkit/modules/shop/shop_entry.gd`

- `item_id` (@export) — 现状：编辑器配置/「稳定 id」
- `price_override` (@export) — 现状：编辑器配置/「价格配置」
- `stock` (@export) — 现状：编辑器配置/「`ShopEntry` 的字段值」
- `conditions` (@export) — 现状：编辑器配置/「执行条件列表」

### `addons/mkit/modules/shop/shop_service.gd`

- `current_shop` (var) — 现状：运行时状态/「当前值」

### `addons/mkit/modules/ui/ui_manager.gd`

- `screen_root_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `screen_scene_map` (@export) — 现状：编辑器配置/「`UIManager` 的字段值」
- `screen_stack` (var) — 现状：运行时状态/「`UIManager` 的字段值」
- `active_screens` (var) — 现状：运行时状态/「是否启用或当前激活状态」
- `modal_screens` (var) — 现状：运行时状态/「`UIManager` 的字段值」

### `addons/mkit/modules/world/dungeon/reward_coordinator.gd`

- `player_group` (var) — 现状：运行时状态/「`RewardCoordinator` 的字段值」

### `addons/mkit/modules/world/dungeon/room_controller.gd`

- `room_definition_id` (@export) — 现状：编辑器配置/「稳定 id」
- `enemy_container_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `entity_spawner_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `reward_count` (@export) — 现状：编辑器配置/「数量上限或计数」
- `spawn_positions` (@export) — 现状：编辑器配置/「`RoomController` 的字段值」
- `runtime` (var) — 现状：运行时状态/「运行时数据」
- `active_enemies` (var) — 现状：运行时状态/「是否启用或当前激活状态」
- `entity_spawner` (var) — 现状：运行时状态/「`RoomController` 的字段值」

### `addons/mkit/modules/world/dungeon/room_definition.gd`

- `room_id` (@export) — 现状：编辑器配置/「稳定 id」
- `scene_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `room_type` (@export) — 现状：编辑器配置/「`RoomDefinition` 的字段值」
- `difficulty_rating` (@export) — 现状：编辑器配置/「`RoomDefinition` 的字段值」
- `size` (@export) — 现状：编辑器配置/「`RoomDefinition` 的字段值」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
- `enemy_spawn_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」
- `reward_pool_ids` (@export) — 现状：编辑器配置/「稳定 id 列表」

### `addons/mkit/modules/world/dungeon/room_graph.gd`

- `nodes` (var) — 现状：运行时状态/「`RoomGraph` 的字段值」
- `start_node` (var) — 现状：运行时状态/「`RoomGraph` 的字段值」
- `boss_node` (var) — 现状：运行时状态/「`RoomGraph` 的字段值」

### `addons/mkit/modules/world/dungeon/room_loader.gd`

- `last_error` (var) — 现状：运行时状态/「`RoomLoader` 的字段值」

### `addons/mkit/modules/world/dungeon/room_node.gd`

- `node_id` (var) — 现状：运行时状态/「稳定 id」
- `room_definition_id` (var) — 现状：运行时状态/「稳定 id」
- `room_type` (var) — 现状：运行时状态/「`RoomNode` 的字段值」
- `next_nodes` (var) — 现状：运行时状态/「`RoomNode` 的字段值」
- `previous_nodes` (var) — 现状：运行时状态/「`RoomNode` 的字段值」

### `addons/mkit/modules/world/dungeon/room_runtime.gd`

- `room_runtime_id` (var) — 现状：运行时状态/「稳定 id」
- `definition_id` (var) — 现状：运行时状态/「稳定 id」
- `cleared` (var) — 现状：运行时状态/「`RoomRuntime` 的字段值」
- `entered` (var) — 现状：运行时状态/「`RoomRuntime` 的字段值」
- `active_enemy_ids` (var) — 现状：运行时状态/「稳定 id 列表」
- `reward_options` (var) — 现状：运行时状态/「`RoomRuntime` 的字段值」

### `addons/mkit/modules/world/dungeon/run_director.gd`

- `first_floor_room_pool` (@export) — 现状：编辑器配置/「`RunDirector` 的字段值」
- `room_scene_container_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `player_group` (@export) — 现状：编辑器配置/「`RunDirector` 的字段值」
- `player_entity_id` (@export) — 现状：编辑器配置/「稳定 id」
- `run_length` (@export) — 现状：编辑器配置/「`RunDirector` 的字段值」
- `run_state` (var) — 现状：运行时状态/「运行时状态」
- `room_graph` (var) — 现状：运行时状态/「`RunDirector` 的字段值」
- `current_room_controller` (var) — 现状：运行时状态/「当前值」

### `addons/mkit/modules/world/dungeon/run_state.gd`

- `run_id` (var) — 现状：运行时状态/「稳定 id」
- `seed` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `run_length` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `first_floor_room_pool` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `current_floor` (var) — 现状：运行时状态/「当前值」
- `current_room_index` (var) — 现状：运行时状态/「当前值」
- `current_room_id` (var) — 现状：运行时状态/「稳定 id」
- `elapsed_time` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `temporary_upgrade_ids` (var) — 现状：运行时状态/「稳定 id 列表」
- `run_currency` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `enemy_scaling_level` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `room_history` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `reward_history` (var) — 现状：运行时状态/「`RunState` 的字段值」
- `rng_state` (var) — 现状：运行时状态/「运行时状态」
- `status` (var) — 现状：运行时状态/「`RunState` 的字段值」

### `addons/mkit/modules/world/portal.gd`

- `target_zone_id` (@export) — 现状：编辑器配置/「稳定 id」
- `target_spawn_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/world/spawn_point.gd`

- `spawn_id` (@export) — 现状：编辑器配置/「稳定 id」

### `addons/mkit/modules/world/world_service.gd`

- `player_group` (@export) — 现状：编辑器配置/「`WorldService` 的字段值」
- `current_zone_id` (var) — 现状：运行时状态/「稳定 id」
- `scene_router` (var) — 现状：运行时状态/「`WorldService` 的字段值」

### `addons/mkit/modules/world/zone_definition.gd`

- `zone_id` (@export) — 现状：编辑器配置/「稳定 id」
- `display_name` (@export) — 现状：编辑器配置/「面向玩家或编辑器的显示名」
- `scene_path` (@export) — 现状：编辑器配置/「资源或节点路径」
- `bgm_id` (@export) — 现状：编辑器配置/「稳定 id」
- `default_spawn_id` (@export) — 现状：编辑器配置/「稳定 id」
- `tags` (@export) — 现状：编辑器配置/「标签集合」
