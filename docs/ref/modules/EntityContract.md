# EntityContract

**文件：** `addons/mkit/modules/entity/entity_contract.gd`  
**用途：** 实体契约入口，统一通过实体约定路径访问组件/控制器/节点，含缺失告警。

## 静态方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `resolve_entity_root(node: Node) -> EntityRoot` | `EntityRoot` | 向上追溯最近的 `EntityRoot` |
| `get_component(node: Node, id_or_type: Variant) -> Node` | `Node` | 获取组件（含契约路径 fallback） |
| `get_controller(node: Node, id_or_type: Variant) -> Node` | `Node` | 获取控制器（含契约路径 fallback） |
| `get_contract_node(node: Node, container: String, id_or_type: Variant) -> Node` | `Node` | 泛化契约节点读取 |
| `get_identity(node: Node) -> EntityIdentity` | `EntityIdentity` | 获取 `EntityIdentity` |
| `get_entity_id(node: Node) -> String` | `String` | 读取实体 ID（回退到节点名） |
| `get_state_machine(node: Node) -> StateMachine` | `StateMachine` | 获取实体状态机 |
| `get_command_receiver(node: Node) -> CommandReceiver` | `CommandReceiver` | 获取实体命令接收器 |
| `has_contract_node(node: Node, container: String, id_or_type: Variant) -> bool` | `bool` | 检查契约路径是否存在 |

## 说明

当无法通过契约入口定位时会通过 `push_warning` 输出一次性去重告警，便于开发期修复路径约定。

## 相关

- → [EntityRoot](EntityRoot.md)
- → [EntitySpawner](EntitySpawner.md)
