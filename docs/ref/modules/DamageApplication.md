# DamageApplication

**文件：** `addons/mkit/modules/combat/damage_application.gd`  
**用途：** 伤害链路的终态装配对象，持有 `DamageResolution` 并可输出 `DamageResult`。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `resolution` | `DamageResolution` | `null` | 解析后的伤害结果 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `from_resolution(resolution: DamageResolution) -> DamageApplication` | `DamageApplication` | 从 `DamageResolution` 生成 |
| `to_result() -> DamageResult` | `DamageResult` | 转换为 `DamageResult`；`resolution == null` 时返回空 `DamageResult` |

## 相关

- → [DamageResolution](DamageResolution.md)
- → [DamageResult](DamageResult.md)
