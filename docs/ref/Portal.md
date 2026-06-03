# Portal

## 概念说明

Portal 是连接两个区域的可互动对象，继承自 Interactable。门、出入口、传送阵都可以是 Portal。被互动时它请求 `world` service 跳转到目标区域的指定落点。

## 设计目的

复用统一的互动协议接入世界导航：玩家走到门前按互动键，InteractionComponent → Interactable.interact() → Portal._interact_impl() 触发 WorldRouter.go_to_zone()，无需为"门"写专用输入或导航代码。目标区域与落点是数据，跳转机制是通用的。

## 文件

`res://addons/mkit/modules/world/portal.gd`

## 字段说明

- **target_zone_id**：传送目标区域 ID，对应一个 ZoneDefinition。为空时互动失败。
- **target_spawn_id**：目标区域内的落点 ID，传给 WorldRouter 以匹配 SpawnPoint。默认 `default`。

（另继承 Interactable 的 interaction_id / display_text / conditions 字段。）

## 接口

```gdscript
class_name Portal
extends Interactable
@export var target_zone_id: String = ""
@export var target_spawn_id: String = "default"
func _interact_impl(context: GameplayContext) -> bool
```

## 函数使用场景

- **`_interact_impl(context)`**：由基类 Interactable.interact()（通过 can_interact 校验后）调用。它检查 target_zone_id 非空、从 ServiceRegistry 取 `world` service，调用 WorldRouter.go_to_zone(target_zone_id, target_spawn_id)；缺 service 或跳转失败时返回 false。

## 使用示例

```gdscript
var portal := Portal.new()
portal.display_text = "Leave Village"
portal.target_zone_id = "zone.field"
portal.target_spawn_id = "field_entrance"
village_scene.add_child(portal)
```
