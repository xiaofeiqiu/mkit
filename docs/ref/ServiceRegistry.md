# ServiceRegistry

## 概念说明

ServiceRegistry 是运行时全局服务的轻量目录。负责注册和解析 RandomService、TimeService、EventRouter、ContentRegistry、CommandRouter、SceneRouter、SaveManager、ProgressionSystem、Analytics 等真正全局服务。很多系统需要共享服务，但不应该到处硬编码 Autoload 路径；统一注册也方便测试时替换成 mock 实现。

## 设计目的

集中注册真正全局的服务，例如 Random、Time、ContentRegistry、EventRouter、SceneRouter、SaveManager、ProgressionSystem、Analytics。不要把具体 gameplay 对象注册成 service。

## 文件

`res://addons/mkit/kernel/services/service_registry.gd`

## 字段说明

- **_services**：内部服务表，按 service_id 保存已注册的 Object。
- **_service_types**：内部期望类型表，记录注册时传入的 expected_class_name。

## 接口

```gdscript
# 由 plugin.gd 注册为 autoload 单例 "ServiceRegistry"。
# 重要：不要在此处声明 class_name ServiceRegistry —— Godot 4 不允许 autoload 名称与 class_name 冲突。
# 在任何地方都通过 autoload 全局访问（例如 ServiceRegistry.get_service("events")）。
extends Node

var _services: Dictionary = {}
var _service_types: Dictionary = {}

func register_service(service_id: String, service: Object, expected_class_name: String = "") -> void

func has_service(service_id: String) -> bool

func get_service(service_id: String) -> Object

func get_typed(service_id: String, expected_class_name: String) -> Object

func get_registered_service_ids() -> Array[String]

func unregister_service(service_id: String) -> void

func clear() -> void
```

## 函数使用场景

- **register_service()**：注册服务入口。例：GameBootstrap 启动时把 EventRouter 注册为 `"events"` 服务，把 ContentRegistry 注册为 `"content"` 服务。
- **has_service()**：存在性查询。例：在取用某个可选服务前先检查它是否已经注册，避免空引用。
- **get_service()**：读取服务入口。例：DealDamageEffect 通过 `get_service("events")` 获取 EventRouter 发出伤害事件，而不是直接依赖节点路径。
- **get_typed()**：带类型验证的读取入口。例：需要确认服务类型是否符合预期时使用，方便排查服务注册错误。
- **get_registered_service_ids()**：返回当前已注册 service_id 的排序列表。例：DebugOverlay 显示运行时服务清单，确认 `time`、`pool`、`ui` 等服务是否已接入。
- **unregister_service()**：注销入口。例：敌人死亡或场景卸载时从 CommandRouter 移除 receiver，避免命令发到无效节点。
- **clear()**：清理重置入口。例：切换存档、退出 run 或重启测试时调用，清空运行时缓存。

## 使用示例

### 注册核心服务

```gdscript
func _ready() -> void:
    var events := EventRouter.new()
    var commands := CommandRouter.new()
    var content := ContentRegistry.new()
    var random := RandomService.new()
    var actions := ActionRunner.new()
    var effects := EffectExecutor.new()

    add_child(events)
    add_child(commands)
    add_child(content)
    add_child(actions)

    ServiceRegistry.register_service("events", events)
    ServiceRegistry.register_service("commands", commands)
    ServiceRegistry.register_service("content", content)
    ServiceRegistry.register_service("random", random)
    ServiceRegistry.register_service("actions", actions)
    ServiceRegistry.register_service("effects", effects)
```

### 在任意系统中获取服务

```gdscript
func grant_reward(option: RewardOption) -> void:
    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_domain_event(DomainEvent.create("reward_granted", "system", "player", {
            "reward_id": option.reward_id
        }))
```

### 基本注册与获取

```gdscript
ServiceRegistry.register_service("random", RandomService.new())
ServiceRegistry.register_service("events", EventRouter.new())
ServiceRegistry.register_service("content", ContentRegistry.new())

var random := ServiceRegistry.get_service("random") as RandomService
```
