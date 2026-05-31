# Combined Implementation Docs

每个文件都把接口设计和对应 usage example 放在一起，并且 example 会直接跟在它说明的接口小节下面。

每个接口小节包含：

- `概念说明`：说明它是什么、负责什么、为什么需要。
- `字段说明`：解释重要字段的含义，以及为什么需要稳定 ID、运行时 ID、上下文、标签、权重、种子等字段。
- `函数使用场景`：说明每个函数在真实 Godot roguelike vertical slice 中什么时候调用、解决什么问题。

每个 usage example 包含：

- `详细实际用例`：用地牢房间、玩家、敌人、奖励、背包、Run 推进等真实场景解释这段代码应该怎么理解。

- [00 Foundation and Folder Structure](00_foundation_and_folder_structure.md)
- [01 Runtime Kernel](01_runtime_kernel.md)
- [02 Content Registry](02_content_registry.md)
- [03 HFSM and Actions](03_hfsm_and_actions.md)
- [04 Conditions and Effects](04_conditions_and_effects.md)
- [05 Entity, Stats, Health, and Combat](05_entity_stats_health_combat.md)
- [06 Ability and Status Effects](06_ability_and_status_effects.md)
- [07 Inventory, Equipment, Loot, and Rewards](07_inventory_equipment_loot_rewards.md)
- [08 Room, Run, and Procedural Generation](08_room_run_and_generation.md)
- [09 AI and Interaction](09_ai_and_interaction.md)
- [10 UI and Feedback](10_ui_feedback.md)
- [11 Save, Progression, and Platform Services](11_save_and_platform_services.md)
- [12 Core Flows, MVP Plan, Debug, and Agent Instructions](12_core_flows_mvp_debug_and_agent_instructions.md)
