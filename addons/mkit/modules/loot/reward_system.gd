class_name RewardSystem
extends LootService
## 兼容旧代码的 LootService 别名；新代码直接通过 `Mkit.loot()` 使用 `LootService`。
## 奖励生成与应用逻辑只在 LootService 中维护，避免两个无状态 system 形成重复入口。
