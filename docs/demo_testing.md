# Demo Testing Guide

## 测试目标

`res://game/demo/bootstrap.tscn` 启动 `res://game/demo/village_rpg/village_rpg_demo.tscn`，用于验证一个完整但很小的 RPG loop 是否能通过 Mkit runtime 串起来。它不是 addon 的可复用接口测试，而是 concrete game content 和多条 module pipeline 的集成冒烟测试。

这个 scene 需要覆盖的主路径：

```text
Bootstrap content
  -> World zone routing
  -> Elder dialogue
  -> Quest accept
  -> Ability cast / burn status tick
  -> Field combat
  -> Quest objective / reward
  -> Loot pickup
  -> XP / level up
  -> Trial cave run / reward upgrade
  -> Elder blessing / stat modifier
  -> Interaction focus / manual quest effects / dash
  -> Shop buy / sell
  -> Local save/load round-trip
  -> Platform services: analytics / rewarded revive / IAP gold pack / cloud save
  -> HUD and event log
```

测试时始终从 `bootstrap.tscn` 进入。直接打开 `village_rpg/village_rpg_demo.tscn` 只适合看布局，因为核心服务和 `village_rpg_content.tres` 是由 `GameBootstrap` 注册的。

## 自动冒烟

先确认 `GODOT` 指向 Godot 4.7-dev：

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
```

运行 demo 的 headless auto-run：

```bash
make demo-test
```

这个 target 会把日志写到 `/tmp/mkit_demo_auto.log`。如果需要改日志路径，可以运行 `DEMO_LOG=/tmp/other.log make demo-test`。

通过标准：

- 进程退出码为 `0`。
- 输出或 `/tmp/mkit_demo_auto.log` 里出现 `[AUTO] demo RPG loop complete`。
- 不出现 `[AUTO] demo RPG loop incomplete`。
- complete 只有在 firebolt 扣 mana、burn status tick 触发、`LogEffect` 发出 `demo_burn_tick` 后才应出现。
- complete 还要求 field beast 被 command -> HFSM -> `TimedAttackAction` melee path 击败；不能依赖 `[COMBAT] command chain stalled; using scripted strike` fallback。
- complete 还要求 trial cave 三房间 run 完成、选择 `upgrade.demo.trial_attack` 奖励，并把 player `attack_power` 提升到 `19`。
- complete 还要求 portal/elder 通过 `InteractionComponent.try_interact()` 聚焦并触发，`quest.demo.supply_request` 通过手动 quest effects 完成，且 `DashAction` 产生位移。
- complete 还要求 `item.demo.field_blade` 已装进 `EquipmentController` 的 `weapon` slot，且 player 的 `attack_power` 达到 `30`(base 10 + trial upgrades 9 + 祝福 5 + 装备 6)。
- complete 还要求本地 `SaveManager` round-trip 恢复 demo 状态。
- complete 还要求 rewarded ad 复活、`com.mkit.demo.gold_pack` IAP、`demo_profile` cloud save/load 都收到 mock 回调。
- 不出现 `missing service`、`could not enter`、`not found`、`transaction failed` 这类 demo 失败日志。
- macOS headless 可能打印一次系统证书相关的 Godot error；如果除此之外 auto-run 完成，可以把它视为环境噪声。

正常主路径日志应该包含这些关键事实：

```text
[WORLD] start -> zone.demo.village
[INTERACT] focus portal.demo.village_to_room
[WORLD] zone.demo.village -> zone.demo.village_room
[INTERACT] focus interaction.demo.elder
[QUEST] accepted quest.demo.field_report
[WORLD] zone.demo.village_room -> zone.demo.village
[WORLD] zone.demo.village -> zone.demo.field
[ACTION] dash moved player
[ABILITY] firebolt burned the beast (mana 50 -> 40)
[STATUS] Demo burn tick
[QUEST] quest.demo.field_report obj.demo.kill_field_beast 1/1
[QUEST] turned in quest.demo.field_report
[LOOT] picked up item.demo.beast_claw x1
[LOOT] picked up item.demo.field_blade x1
[XP] level 1 -> 2
[TRIAL] started seed=
[TRIAL] finished completed
[STAT] elder blessing attack_power 19 -> 24
[QUEST] accepted quest.demo.supply_request
[QUEST] quest.demo.supply_request obj.demo.receive_supply_note 1/1
[QUEST] turned in quest.demo.supply_request
[QUEST] manual supply request completed
[EQUIP] equipped field blade attack_power 24 -> 30
[SHOP] bought item.demo.herb_potion x1 for 10 gold
[SHOP] sold item.demo.beast_claw x1 for 4 gold
[AD] rewarded revive completed
[IAP] gold pack completed +25 gold
[SAVE] round-trip restored demo state
[CloudSave] saved demo_profile
[CloudSave] loaded demo_profile
[AUTO] demo RPG loop complete
```

## 手动冒烟流程

启动可视化场景：

```bash
$GODOT --path . res://game/demo/bootstrap.tscn
```

### 1. 初始状态

进入后应在 `Village`：

- `Zone: Village`
- `Quest: talk to elder`
- `Player: HP 100/100  Lv1 XP 0/40  gold 10`
- `Bag: empty`
- `Shop: closed`
- `QuestLogPanel` 显示没有 active quest
- 事件日志出现 `[DEMO] RPG loop demo ready` 和 `[WORLD] start -> zone.demo.village`

如果 HUD 显示缺少 `world`、`quest`、`shop` 等服务，通常是没有从 `bootstrap.tscn` 启动。

### 2. World routing

靠近村庄右侧 room portal，看到 `[INTERACT] focus portal.demo.village_to_room` 后按 `R` 进入 elder room：

- `Zone` 变为 `Elder Room`
- 当前 `WorldHost` 内容应切到 `VillageRoom`
- 事件日志出现 `zone.demo.village -> zone.demo.village_room`

靠近 room 内的返回 portal，看到 `[INTERACT] focus portal.demo.room_to_village` 后按 `R` 应回到村庄，并显示 `zone.demo.village_room -> zone.demo.village`。

靠近 field portal，看到 `[INTERACT] focus portal.demo.village_to_field` 后按 `G` 从村庄进入 field：

- `Zone` 变为 `Field`
- 当前 `WorldHost` 内容应切到 `Field`
- field 内能看到由 `entity.demo.field_beast` 数据生成的 `FieldBeast`

靠近 field 的返回 portal，看到 `[INTERACT] focus portal.demo.field_to_village` 后按 `G` 应回到村庄，并显示 `zone.demo.field -> zone.demo.village`。

### 3. Dialogue and quest

进入 elder room 后靠近 Elder，看到 `[INTERACT] focus interaction.demo.elder` 后按 `T` 开始对话：

- `DialoguePanel` 变为可见
- 日志出现 `[DIALOGUE] started dialogue.demo.elder`
- 对话内容来自 `dialogue.demo.elder`

再次按 `T` 选择第一项 `I'll check the field.`：

- `quest.demo.field_report` 被接受
- `QuestLogPanel` 显示 `Field Report`
- HUD 显示 quest 状态为 `active`，目标进度为 `beast 0/1`
- 日志出现 `[QUEST] accepted quest.demo.field_report`

再按一次 `T` 结束对话，日志出现 `[DIALOGUE] ended dialogue.demo.elder`。

### 4. Ability, status, combat, quest reward, loot, XP

回到村庄后按 `G` 进入 field，先按 `Shift` 验证冲刺，再按 `F` 施放 firebolt，最后按 `K` 击败 field beast。

预期结果：

- `Shift` 通过 `BuiltinCommands.DASH` 进入 dash state，日志包含 `[ACTION] dash moved player`
- firebolt 扣除 10 mana，并给 field beast 施加 `status.demo.burn`
- burn tick 触发一次伤害和 LogEffect，日志包含 `[STATUS] Demo burn tick`
- 玩家受到 enemy AI 至少一次反击，HP 下降但不会立刻死亡
- field beast 被击败，日志包含 `[COMBAT] defeated entity_demo_field_beast_`
- quest 目标推进到 `1/1`
- quest 自动 turn in，日志包含 `[QUEST] turned in quest.demo.field_report`
- 背包获得 `village_charm x1`
- 背包获得 `beast_claw x1`
- 背包获得 `field_blade x1`(来自 `loot.demo.field_blade` 保证掉落)
- XP 增加 `65`，等级从 `1` 升到 `2`
- 金币从 `10` 变为 `40`

击败后继续按 `K` 不应该重复发奖励、loot 或 XP；如果重复获得 `beast_claw`、`field_blade`、`village_charm` 或再次升级，就是幂等性回归。

### 5. Trial cave

field 中按 `C` 进入 trial cave，清完每个 room 后用 `1`/`2`/`3` 选择奖励。auto-run 固定选择 `reward.demo.trial_attack`。

预期结果：

- 日志出现 `[TRIAL] started seed=`
- 依次进入 3 个 `room.demo.trial_*`
- 每个 room 清完后出现 `[TRIAL] choose reward after room N`
- 选择 attack reward 后出现 `[TRIAL] upgrade recorded upgrade.demo.trial_attack`
- 第 3 个 room 完成后出现 `[TRIAL] finished completed`
- 如果三次都选择 attack reward，player `attack_power` 从 `10` 提升到 `19`

### 6. Elder blessing

回村后按 `R` 进入 elder room，靠近 Elder 后按 `Y` 选择 blessing 路径。

预期结果：

- 完成 trial attack reward 后，日志出现 `[STAT] elder blessing attack_power 19 -> 24`
- 如果跳过 trial，日志应为 `[STAT] elder blessing attack_power 10 -> 15`
- blessing 来自 `dialogue.demo.elder` 的第二项 choice
- 效果通过 `ApplyStatModifierEffect` 给 player 的 `StatsComponent` 添加永久 `attack_power +5` modifier

### 7. Manual quest effects

留在 elder room 并靠近 Elder 后按 `M`，走第三项手动支线任务。

预期结果：

- `quest.demo.supply_request` 被接受
- `AdvanceObjectiveEffect` 把 `obj.demo.receive_supply_note` 推进到 `1/1`
- `CompleteQuestEffect` 把 quest 置为 `turned_in`
- 日志包含 `[QUEST] manual supply request completed`

再靠近返回 portal，按 `R` 回到村庄。

### 8. Equip the field blade

回村后按 `E` 把 field 掉落的 `field_blade` 装进 `weapon` slot：

- 完成 trial + blessing 后，日志出现 `[EQUIP] equipped field blade attack_power 24 -> 30`
- `EquipmentController` 通过 `StatModifier` 给 `StatsComponent` 加 `attack_power +6`
- blade 仍保留在背包里,装备槽只引用同一个 `ItemInstance`(`EquipmentController` 与 `InventoryController` 解耦,equip 不改动背包条目)
- 再按一次 `E` 卸下,`attack_power` 还原到 `24`(日志 `[EQUIP] unequipped ...`),blade 仍在背包,可再次装备

equip 后的 `attack_power` 会被 `CombatResolver` 读到,提高后续战斗伤害。auto-run 会走一遍 equip → unequip → 再 equip,验证 toggle 不会丢失 blade,并在结束时保持装备状态。

### 9. Shop buy and sell

回到村庄后按 `B`：

- `ShopPanel` 变为可见
- 日志出现 `[SHOP] opened shop.demo.village_supply`
- 购买 `herb_potion x1`
- 金币从 `40` 变为 `30`
- 背包显示 `herb_potion x1`

按 `V` 出售 claw：

- `beast_claw` 从背包移除
- 金币从 `30` 变为 `34`
- 日志出现 `[SHOP] sold item.demo.beast_claw x1 for 4 gold`

离开村庄时 shop UI 应关闭，`Shop` HUD 应回到 `closed`。

### 10. Potion use

`H` 是额外的 consumable 检查，不属于 auto-run 的完成条件。建议在完成买药后单独测一次：

- 如果玩家 HP 低于 `100/100`，按 `H` 后应恢复，且不能超过 `max_hp`
- `herb_potion` 从背包移除
- 日志出现 `[ITEM] used herb potion HP ... -> ...`

如果在满血时使用，HP 应保持 `100/100`，不能超过 `max_hp`。

### 11. Local save/load

按 `S` 保存本地状态，改动状态后按 `L` 读取：

- 日志出现 `[SAVE] saved demo state`
- 日志出现 `[SAVE] loaded demo state`
- auto-run 的完成门还要求 `[SAVE] round-trip restored demo state`

### 12. Platform services

按 `D` 会让玩家死亡并走 rewarded ad revive:

- 日志出现 `[AD] showing rewarded revive`
- `AdServiceMock.rewarded_ad_completed("revive")` 回调后玩家复活到 50% HP
- 日志出现 `[AD] rewarded revive completed`

按 `P` 在村庄 shop 中购买金币包:

- 日志出现 `[IAP] purchasing com.mkit.demo.gold_pack`
- `IAPServiceMock.purchase_completed` 回调后金币增加 `25`
- 日志出现 `[IAP] gold pack completed +25 gold`

按 `O` / `U` 走 cloud save / load:

- `O` 先调用本地 `SaveManager.save_game(get_tree().root)`，再上传 slot `demo_profile`
- `U` 从 `CloudSaveServiceMock` 拉回同一 slot，并通过 `SaveManager.load_game(get_tree().root)` 恢复本地状态
- 日志出现 `[CloudSave] saved demo_profile` 和 `[CloudSave] loaded demo_profile`

## 负向检查

这些检查不用每次都跑，但改场景节点名、portal、shop、dialogue 或 resource id 时应该跑：

- 在村庄外按 `B` 或 `V`，应提示 `[SHOP] return to the village supply stall`。
- 没有 `beast_claw` 时按 `V`，应提示 `[SHOP] no beast claw to sell`。
- 不在 elder room 按 `T`，应提示 `[DIALOGUE] enter the elder room first`。
- 不在 elder room 按 `Y`，应提示 `[DIALOGUE] enter the elder room first`。
- 不在 field 按 `K`，应提示 `[COMBAT] go to the field first`。
- 未买 potion 时按 `H`，应提示 `[ITEM] no herb potion in inventory`。
- 没有 `field_blade`(还没击败 beast)时按 `E`，应提示 `[EQUIP] no field blade to equip`。
- 重复击败 field beast 不应重复发放 quest reward、loot 或 XP。

## 需要一起保护的底层测试

demo 本身是 demo content，不应该把具体 `field_beast`、`herb_potion`、`Village Supply` 写进 addon unit tests。底层机制由已有 GUT 覆盖；改动不同范围时跑对应套件。

只改 `game/demo/village_rpg/` content 或 scene wiring：

```bash
make int
make demo-test
```

改 world、dialogue、quest、shop、loot、inventory、progression、combat、UI 或 audio 模块行为：

```bash
make ut
make int
```

迭代时可以先跑相关单文件：

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_world_router.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_dialogue_controller.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_quest_system.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_shop_controller.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_loot_system.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_inventory_controller.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_progression_system.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/modules/test_combat_resolver.gd -gexit
```

相关 integration tests：

```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_world_pipeline_integration.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_dialogue_pipeline_integration.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_quest_pipeline_integration.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_shop_pipeline_integration.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_gameplay_pipeline_integration.gd -gexit
```

## Resource contract checklist

改 `res://game/demo/village_rpg/resources/village_rpg_content.tres` 时检查这些 content id 和 scene/node contract：

- 三个 zones 存在：`zone.demo.village`、`zone.demo.village_room`、`zone.demo.field`
- 每个 `ZoneDefinition.scene_path` 指向存在的 `.tscn`
- `player.tscn` 存在 `Components/InteractionComponent` 和 `StateMachine/Player/Dash`
- portal 节点是 `Area2D`，存在 `ToRoom/Interactable`、`ToField/Interactable` 或 `ToVillage/Interactable` child
- portal 的 `target_zone_id` 和 `target_spawn_id` 能匹配对应 zone 和 `SpawnPoint.spawn_id`
- elder room scene 内存在 `Elder/Controllers/DialogueInteractable` 和 `Elder/InteractionArea/Interactable`
- dialogue `dialogue.demo.elder` 的第一项 choice 执行 `AcceptQuestEffect`
- dialogue `dialogue.demo.elder` 的第二项 choice 执行 `ApplyStatModifierEffect`
- dialogue `dialogue.demo.elder` 的第三项 choice 执行 supply request 的 accept + advance + complete effects
- `max_hp`、`attack_power`、`defense` 三个 `StatDefinition` 注册进 content registry
- `status.demo.burn` 包含 tick damage、`LogEffect` 和 defense debuff `StatModifierDefinition`
- quest objective 监听 `enemy_killed`，并匹配 tag `field_beast`
- `quest.demo.supply_request` 注册进 content registry，objective 为 `obj.demo.receive_supply_note`
- `effect.demo.advance_supply_request` 是 `AdvanceObjectiveEffect`，`effect.demo.complete_supply_request` 是 `CompleteQuestEffect`
- `entity.demo.field_beast` 注册进 content registry，`scene_path` 指向 `field_beast.tscn`
- field beast 的 `EntityIdentity.tags` 包含 `field_beast`
- field beast 有 `Components/HealthComponent`，死亡不销毁节点也不能重复 loot
- trial cave 存在 `room.demo.trial_01/02/03`、`reward.demo.trial_attack`、`upgrade.demo.trial_attack`，并能完成 3 room run
- `loot.demo.field_beast` 至少能产出 `item.demo.beast_claw`
- `loot.demo.field_blade` 保证产出 `item.demo.field_blade`(`rolls=1`、`allow_empty=false`、单 entry)
- `item.demo.field_blade` 是 `equipment_slot="weapon"`、不可堆叠,且带 `attack_power +6` 的 `StatModifierDefinition`
- `shop.demo.village_supply` 能买 `item.demo.herb_potion`，且允许卖出 `item.demo.beast_claw`
- `item.demo.herb_potion` 的 `use_effects` 包含 heal effect
- quest reward 发 `item.demo.village_charm` 和 `gold`

## 常见失败定位

`[WORLD] service missing` 或多个 service missing：通常是直接跑了 `village_rpg/village_rpg_demo.tscn`，改用 `bootstrap.tscn`。

`[WORLD] could not enter zone.demo.*`：检查 zone 是否注册进 `village_rpg_content.tres`，以及 `scene_path` 是否存在。

`[WORLD] missing portal`：检查当前 zone scene 里的 portal 节点名是否仍然是 `ToRoom`、`ToField` 或 `ToVillage`。

没有 `[INTERACT] focus ...`：检查 player 的 `InteractionComponent`，portal / elder interaction area 的 collision shape，以及 interactable child 路径。

`[DIALOGUE] elder not found` 或 `elder has no DialogueInteractable`：检查 `village_room.tscn` 的 `Elder` 节点名、entity layout 和 `Elder/InteractionArea/Interactable`。

`[COMBAT] field beast not found`：检查 `field.tscn` 的 `FieldBeastSpawn` marker、`village_rpg_content.tres` 里的 `entity.demo.field_beast`，以及生成后的 `FieldBeast` 节点名。

`[ACTION] dash moved player` 没出现：检查 `StateMachine/Player/Dash`、`player_dash_state.gd`、`BuiltinCommands.DASH` 的 command receiver 映射和 `DashAction`。

`[TRIAL] finished completed` 没出现：检查 trial room definitions、reward definitions、`RunDirector` host 接管/归还，以及 `RewardSelectionUI` 选择是否调用。

`[STATUS] firebolt did not apply burn` 或 `burn tick was not observed`：检查 `ability.demo.firebolt` 的 effects、`status.demo.burn.tick_interval` 和 tick 上的 `LogEffect.event_type = "demo_burn_tick"`。

`[QUEST]` 没有推进到 `1/1`：检查 field beast tag、quest objective 的 `event_type`、`match_key`、`match_value`，以及 death event 是否发出。

`[QUEST] manual supply request completed` 没出现：检查 elder 第三项 choice、`effect.demo.advance_supply_request`、`effect.demo.complete_supply_request` 和 `quest.demo.supply_request` 注册。

`[SHOP] transaction failed`：检查金币、库存、背包容量、shop entry、item id 和 sell multiplier。

`[AUTO] demo RPG loop incomplete`：从它前面的最后一条成功日志判断卡在哪条 pipeline，再按上面的 resource contract 逐项查。
