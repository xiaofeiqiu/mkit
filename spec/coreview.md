# Code Review: SL Design P1a

## Scope

本次审核覆盖当前工作区中 `spec/sl-design.md` P1a 对应的 SaveableComponent 与组件序列化改动:

- `addons/mkit/kernel/save/saveable_component.gd`
- Health / Stats / ResourcePool / Status / Ability / Inventory / Equipment 组件与控制器
- `ItemInstance` / `StatModifier` payload helper
- `test/unit/modules/test_saveable_components.gd`
- 相关 docs/ref 与 `spec/sl-design.md` 进度更新

## Addressed Findings

### Addressed: multi-charge ability state is now round-tripped

位置:

- `addons/mkit/modules/abilities/ability_controller.gd:135`
- `addons/mkit/modules/abilities/ability_controller.gd:147`
- `addons/mkit/modules/abilities/ability_instance.gd:32`

原问题:`AbilityController.to_save_data()` 只保存 `learned` 和 `cooldowns`;`from_save_data()` 在 cooldown 剩余时间大于 0 时把 `current_charges` 设为 0。`AbilityInstance.is_cooldown_ready()` 只看 `current_charges > 0`,所以多充能技能会在读档后丢失剩余充能。

例:一个 `charges = 3` 的技能当前还有 2 次可用,同时 recharge timer 正在跑。当前 payload 只能保存 cooldown,读档后会恢复成 0 charges,技能被错误锁住。

处理:

- Ability payload 增加 `charges` 与 `recharge_durations`。
- 恢复时按 `AbilityDefinition.charges` clamp `current_charges`。
- 新增 multi-charge round-trip 与 recharge continuation unit test。

### Addressed: restored status effects rebind source when possible

位置:

- `addons/mkit/modules/status_effects/status_effect_controller.gd:102`
- `addons/mkit/modules/status_effects/status_effect_controller.gd:170`
- `addons/mkit/modules/status_effects/status_effect_controller.gd:172`

原问题:`StatusEffectController.to_save_data()` 保存了 `source_id`,但 `from_save_data()` 通过 `instance.setup(definition, null, owner, ...)` 恢复,使 `StatusEffectInstance.source` 为 `null`。后续 `_execute_effects()` 会把 `context.source = instance.source`,因此读档后的 `effects_on_tick` / `effects_on_remove` 会拿到空 source。

这会影响依赖 source 的效果,例如伤害归属、治疗来源、基于 source 位置的 SpawnSceneEffect、日志或 analytics attribution。

处理:

- `StatusEffectController.from_save_data()` 通过 `source_id` 在当前 scene tree 中查找带 `EntityIdentity.entity_id` 的来源实体。
- `_execute_effects()` 同时把 `source_id` 写入 `GameplayContext.payload`。
- 新增 tick effect unit test,验证读档恢复后的 status tick 能拿到原 source node。

### Addressed: definition base stats are marked as save baseline

位置:

- `addons/mkit/modules/stats/stats_component.gd:25`
- `addons/mkit/modules/stats/stats_component.gd:196`
- `addons/mkit/modules/entity/entity_spawner.gd:37`
- `addons/mkit/modules/entity/entity_spawner.gd:82`

原问题:`StatsComponent` 在 `_ready()` 时记录 `_initial_base_stats`,之后 `_get_base_overrides()` 用它判断哪些 base stat 是运行时 override。`EntitySpawner.spawn_entity()` 当前先 `parent.add_child(entity)`,再调用 `_initialize_stats()` 用 `set_base_stat()` 写入 `EntityDefinition.base_stats`。

结果是:通过 EntitySpawner 生成的实体会把定义里的静态 base stats 误判为运行时 override。直接 round-trip 通常不会坏,但会违背“静态 Definition 不进存档”的设计,也可能导致后续内容平衡调整后旧存档继续覆盖新定义值。

处理:

- `StatsComponent` 增加 `mark_save_baseline()`。
- `EntitySpawner._initialize_stats()` 写完 `EntityDefinition.base_stats` 后调用 `mark_save_baseline()`。
- 新增 EntitySpawner unit test,验证刚 spawn 出来的实体未发生运行时 stat 改动时 `base_overrides` 为空。

## Test Coverage Notes

已覆盖:

- P1a 组件均 `extends SaveableComponent`
- Health HP clamp + dead state
- Stats 永久 modifier 保存、临时 modifier 不保存
- ResourcePool current values round-trip
- Status active state + stat modifier restore
- Ability learned ids、cooldown、multi-charge current_charges 与 recharge continuation restore
- Inventory item payload
- Equipment slots + rolled affixes + stat modifier restore

剩余风险:

- Status source resolver 依赖当前 scene tree 中存在带同一 `EntityIdentity.entity_id` 的实体。若来源实体尚未重建或已被移除,`context.source` 仍会为 null,但 `context.payload.source_id` 会保留。
- `recharge_durations` 保存的是运行时 recharge 时长;若读档时 AbilityDefinition cooldown 已变,旧存档会继续旧 recharge 节奏直到本轮 recharge 完成。

## Verification Observed

- `make ut`:kernel 7 scripts / 102 tests / 165 asserts,102/102 passing;modules 16 scripts / 213 tests / 599 asserts,213/213 passing.
- `make int`:11 scripts / 35 tests / 588 asserts,35/35 passing.

## Merge Recommendation

本次 review 提出的三条问题均已处理,并由 focused unit tests 覆盖。P1a 当前可以进入后续 P1b 实体聚合器实现。

进入 P1b 前需要保留两点设计注意:

- `StatusEffectController` 只能在来源实体已存在于当前 scene tree 时重新绑定 `source`;后续 EntitySaver / SaveCoordinator 的恢复顺序需要保证来源实体先可解析,否则仍只能依赖 `payload.source_id`。
- `AbilityController.recharge_durations` 代表保存时的运行时 recharge 时长;若 AbilityDefinition.cooldown 在读档前被调参,当前进行中的 recharge 会继续旧时长直到本轮完成。
