# Platform Adapter Layer

## Layer Level

Platform Adapter Layer 是最底层的外部服务适配层。它通过接口和 mock 把广告、IAP、Analytics、Cloud Save 等平台能力隔离在 framework 边界处，避免 gameplay 代码直接耦合 SDK 或远端服务。

Kernel Layer 和上层代码只能通过这些 service interface 使用平台能力；具体平台 SDK adapter 应实现这些接口，并通过 `ServiceRegistry` 或 bootstrap 注入。

## Scope

- Source scope: currently `res://addons/mkit/kernel/services/` for platform-facing service interfaces and mocks.
- Responsibility: platform service contracts, test doubles, future external SDK adapters.
- Expected stability: high for interfaces, variable for concrete adapters. SDK 变化应被限制在 adapter 内部。

## Classes

- [AdService](ref/AdService.md)
- [AdServiceMock](ref/AdServiceMock.md)
- [AnalyticsService](ref/AnalyticsService.md)
- [AnalyticsServiceMock](ref/AnalyticsServiceMock.md)
- [CloudSaveService](ref/CloudSaveService.md)
- [CloudSaveServiceMock](ref/CloudSaveServiceMock.md)
- [IAPService](ref/IAPService.md)
- [IAPServiceMock](ref/IAPServiceMock.md)
