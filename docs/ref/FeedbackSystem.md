# FeedbackSystem

## 概念说明

FeedbackSystem 是玩法事件到表现反馈的桥。它监听伤害、死亡、拾取等事件并播放音效、VFX 和伤害数字。Combat 代码不应该直接知道怎么播放声音或生成特效。

## 设计目的

把游戏表现层（音效、VFX、伤害数字）与玩法层（CombatResolver、HealthComponent）彻底解耦，通过监听 EventRouter 信号响应玩法事实，使换一套表现资产不需要改战斗代码。

## 文件

`res://addons/mkit/modules/ui/feedback_system.gd`

## 字段说明

- **damage_number_system_path**：资源或节点路径。例：用 damage_number_system_path 指向场景或节点，方便在 Inspector 中配置。
- **vfx_spawner_path**：资源或节点路径。例：用 vfx_spawner_path 指向场景或节点，方便在 Inspector 中配置。
- **audio_manager_path**：资源或节点路径。例：用 audio_manager_path 指向场景或节点，方便在 Inspector 中配置。
- **damage_numbers**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **vfx**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **audio**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name FeedbackSystem
extends Node
@export var damage_number_system_path: NodePath
@export var vfx_spawner_path: NodePath
@export var audio_manager_path: NodePath
var damage_numbers: DamageNumberSystem
var vfx: VFXSpawner
var audio: AudioManager
```

## 函数使用场景

- **`_ready()`**：缓存 DamageNumberSystem、VFXSpawner、AudioManager 子节点，并连接 EventRouter 的 `damage_applied` 和 `entity_died` 信号。
- **`_on_damage_applied(result)`**：内部信号处理器，当 damage_applied 事件到来时，在目标位置显示伤害数字（含暴击判断）、生成 hit VFX、播放 hit 音效。
- **`_on_entity_died(entity_id, entity_ref)`**：内部信号处理器，当 entity_died 事件到来时，在实体位置生成死亡 VFX 并播放死亡音效。

## 使用示例

### 自动响应 combat event

```gdscript
# FeedbackSystem 在 _ready() 内部连接 EventRouter 信号，
# 外部不需要手动连接，只需将节点加入场景即可。
var feedback := $FeedbackSystem as FeedbackSystem
```

### 手动播放反馈

```gdscript
func play_pickup_feedback(position: Vector2) -> void:
    $FeedbackSystem.vfx.spawn("pickup", position)
    $FeedbackSystem.audio.play_sfx("pickup")
```
