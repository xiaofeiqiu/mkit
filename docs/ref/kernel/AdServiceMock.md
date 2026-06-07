# AdServiceMock

**层：** Kernel  
**文件：** `addons/mkit/kernel/services/ad_service_mock.gd`  
**继承：** `extends AdService`  
**服务 ID：** `"ads"`（`GameBootstrap` 默认注册）

## 职责

默认广告适配器。用于本地开发和无平台 SDK 环境：任意激励广告 placement 都视为可用，调用展示后短延迟发出完成信号。

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `is_rewarded_ad_ready(placement_id: String) -> bool` | `bool` | 总是返回 `true` |
| `show_rewarded_ad(placement_id: String) -> void` | — | 等待 0.5 秒后发 `rewarded_ad_completed(placement_id)` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var ads: AdService = ServiceRegistry.get_service("ads") as AdService
if ads.is_rewarded_ad_ready("revive"):
    ads.show_rewarded_ad("revive")
```

### 典型场景（Level 2）

```gdscript
func request_revive_ad() -> void:
    var ads: AdService = ServiceRegistry.get_service("ads") as AdService
    if ads == null or not ads.is_rewarded_ad_ready("revive"):
        return
    ads.rewarded_ad_completed.connect(func(placement_id: String) -> void:
        if placement_id == "revive":
            _revive_player()
    )
    ads.show_rewarded_ad("revive")
```

## 相关

- → [AdService](AdService.md) · [GameBootstrap](GameBootstrap.md)
