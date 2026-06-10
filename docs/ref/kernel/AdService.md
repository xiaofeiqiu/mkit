# AdService

**层：** Kernel（平台适配层）  
**文件：** `addons/mkit/kernel/services/ad_service.gd`  
**继承：** `extends Node`  
**服务 ID：** `"ads"`（默认注册 `AdServiceMock`）

## 职责

激励广告的平台适配抽象。基类默认"未实现"（`show_rewarded_ad` 直接发失败）；`GameBootstrap` 默认注册 `AdServiceMock`。接真实广告 SDK 时继承实现并替换注册。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `is_rewarded_ad_ready(placement_id: String) -> bool` | `bool` | 广告是否就绪 |
| `show_rewarded_ad(placement_id: String) -> void` | — | 展示激励广告 |

## 信号

| 信号名 | 参数 | 触发时机 |
|--------|------|----------|
| `rewarded_ad_completed` | `placement_id` | 观看完成（应发奖励）|
| `rewarded_ad_failed` | `placement_id, reason` | 失败/未实现 |

## AdServiceMock

**文件：** `addons/mkit/kernel/services/ad_service_mock.gd` · `extends AdService`  
开发期默认实现：`is_rewarded_ad_ready` 恒 `true`；`show_rewarded_ad` 等 0.5s 后发 `rewarded_ad_completed`。

## 使用模式

### 最小示例（Level 1）

```gdscript
var ads := Mkit.ads()
ads.rewarded_ad_completed.connect(func(_p: String): give_bonus_coins(50))
if ads.is_rewarded_ad_ready("revive"):
    ads.show_rewarded_ad("revive")
```

## 相关

- → [GameBootstrap](GameBootstrap.md)（替换点）· [IAPService](IAPService.md)
