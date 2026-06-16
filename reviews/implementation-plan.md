# FSM + HFSM Rename Implementation Plan

## 背景

mkit kernel 当前只有一种状态机实现：`addons/mkit/kernel/state_machine/`
下的 `StateMachine` + `State`。它实际上是**层级状态机（HFSM）**：

- `State` 节点可嵌套，持有 `parent_state` / `active_child` / `initial_child_state_id`。
- 转移用 `/` 分隔的层级路径（如 `Player/Attack`），`transition_to` 会计算
  最近公共祖先（LCA），逐层 `exit` 再逐层 `enter`。
- `handle_command` 从当前叶子状态向父状态**冒泡**，任一层消费即停止。
- `_process` / `_physics_process` 会沿「根 → 叶子」整条激活链逐个 tick。

对很多实体来说，层级 / LCA / 命令冒泡都用不到。一个**扁平 FSM**（一组互斥状态 +
单层转移）更易读、易测。

本计划做两件事（均已与需求方确认）：

1. **把现有「名不副实」的 `StateMachine` / `State` 重命名为 HFSM 专属类名**，
   让它的层级语义在类名上自解释。
2. **新增一个扁平 FSM**，并通过一个共享基类让 **FSM 与 HFSM 都能即插即用地接入
   标准实体场景**（`EntityRoot` / `CommandReceiver` / `EntityContract`）。

## 目标

1. 现有 HFSM 重命名：`StateMachine -> Hfsm`、`State -> HfsmState`，行为不变，
   现有测试保持全绿。
2. 新增扁平 FSM：一组互斥状态，按 `state_id` 单层转移，无嵌套 / LCA / 命令冒泡，
   但保留与 HFSM 一致的 hook 集合、共享 `Blackboard`、相同信号语义、
   `request_transition` 自助转移。
3. 抽出共享基类 `StateMachineBase`，统一命令入口 `handle_command(command) -> bool`
   与 `state_changed` / `transition_failed` 信号；`Hfsm` 与 `Fsm` 都继承它。
4. 让实体接线层（`EntityRoot` / `CommandReceiver` / `EntityContract`）面向
   `StateMachineBase` 编程，从而任一种状态机都能挂在 `EntityRoot/StateMachine`
   节点下被命令管线驱动。
5. 完整 GUT 单测 + 集成测试、`##` 文档注释、生成 API 页、glossary 区分 HFSM / FSM。
6. 不引入 `addons/mkit/ -> game/` 依赖，不在 `addons/mkit/` 写具体 game 内容。

## 非目标

- 不改 HFSM 的转移 / 冒泡 / tick 行为；重命名是纯机械替换 + 接基类。
- 不改实体场景的**节点名**：`EntityRoot` 下的状态机子节点仍叫 `StateMachine`
  （遵守 CLAUDE.md「保留 EntityRoot 场景结构与子节点名」）。变的只是该节点挂的
  脚本与对应类型。
- 不引入数据驱动转移表（声明式 `from -> on_command -> to`）；列入后续工作。
- 不把现有 game 示例实体从 HFSM 迁到 FSM；保持现状，FSM 通过新示例验证。

## 命名与类层级（已确认）

类名采用 PascalCase 缩写写法（Godot / GDScript 惯例）。若需求方更想要字面全大写
`HFSM` / `FSM`，仅替换标识符，结构不变。

```text
StateMachineBase   (extends Node)          # 新增：共享契约基类
├── Hfsm           (was StateMachine)      # 重命名：层级状态机
└── Fsm            (new)                    # 新增：扁平状态机

HfsmState          (was State)             # 重命名：层级状态基类（可嵌套）
FsmState           (new)                    # 新增：扁平状态基类（无嵌套）
```

文件：

```text
addons/mkit/kernel/state_machine/state_machine_base.gd   # 新增 StateMachineBase
addons/mkit/kernel/state_machine/hfsm.gd                 # state_machine.gd 重命名
addons/mkit/kernel/state_machine/hfsm_state.gd           # state.gd 重命名
addons/mkit/kernel/state_machine/fsm.gd                  # 新增 Fsm
addons/mkit/kernel/state_machine/fsm_state.gd            # 新增 FsmState
```

`.gd.uid` 由 Godot import 自动生成 / 更新，不手写。

## HFSM 与 FSM 关键差异

| 维度 | HFSM（`Hfsm`） | 扁平 FSM（`Fsm`） |
| --- | --- | --- |
| 状态结构 | 树形可嵌套 | 扁平，状态均为 `Fsm` 直接子节点 |
| 寻址 | `/` 层级路径 `Player/Attack` | 单个 `state_id`，如 `Idle` |
| 转移 | LCA：逐层 exit / enter | 单步：当前 `exit` → 目标 `enter` |
| 命令处理 | 叶子向父冒泡 | 仅当前状态，不冒泡 |
| tick | 沿整条激活链逐层 tick | 只 tick 当前状态 |
| 进入复合态 | 跟随 `initial_child_state_id` 下钻 | 无 |
| 命令入口 | `handle_command`（来自 `StateMachineBase`） | 同左 |

## 实现计划

### Phase 0：共享基类 `StateMachineBase`

新增 `state_machine_base.gd`：

```gdscript
class_name StateMachineBase
extends Node

signal state_changed(previous: String, current: String)
signal transition_failed(from: String, to: String, reason: String)

var owner_entity: Node = null
var blackboard: Blackboard = Blackboard.new()

func handle_command(command: GameCommand) -> bool:
    return false
```

- 信号与 `owner_entity` / `blackboard` 上提到基类，子类**不得重复声明同名信号**
  （GDScript 会报错），改为继承并 `emit`。
- `handle_command` 为虚方法，子类覆写。
- `transition_to` / `get_current_path` / `get_current_id` 因签名不同（路径 vs id）
  仍各自定义在子类；命令管线只依赖 `handle_command`，无需进基类。

### Phase 1：重命名现有 HFSM

机械替换，行为不变：

1. **文件改名 + class_name**
   - `state_machine.gd -> hfsm.gd`，`class_name StateMachine -> Hfsm`，
     `extends Node -> extends StateMachineBase`；删除其重复的 `state_changed` /
     `transition_failed` 信号声明、`owner_entity` / `blackboard` 字段声明（改为继承）。
   - `state.gd -> hfsm_state.gd`，`class_name State -> HfsmState`；其
     `var state_machine: StateMachine` / `setup(machine: StateMachine, ...)`
     改为 `Hfsm`。
2. **game 状态子类**（8 个，均 `extends State -> extends HfsmState`）：
   `game/entities/states/{player_idle,player_move,player_attack,player_dash,
   player_cast_ability,enemy_idle,enemy_move,enemy_attack}_state.gd`。
3. **.tscn 脚本路径**（3 个实体场景的 `ext_resource ... path=`）：
   `game/entities/{player,field_beast,npc_elder}.tscn` 把
   `kernel/state_machine/state_machine.gd` → `hfsm.gd`、`state.gd` → `hfsm_state.gd`。
   **节点名 `StateMachine` 不变。**
4. **测试**：`test/unit/kernel/test_state_machine.gd` 与
   `test/integration/test_gameplay_pipeline_integration.gd` 里的
   `StateMachine` / `State` 标识符替换为 `Hfsm` / `HfsmState`（文件名是否一并改为
   `test_hfsm.gd` 见 Phase 4）。
5. **`##` doc 注释中的散文提及**：`game_command.gd`、`command_receiver.gd`、
   `ability_controller.gd`、`entity_root.gd` 等注释里出现的「StateMachine」按语境改为
   「状态机 / Hfsm / Fsm」，避免文档与新类名脱节。

> 注：模块控制器（ability / status / room / inventory / equipment controller）里出现的
> `StateMachine` 经核对均为 `##` 注释散文，不是类型引用，按第 5 点处理即可。

### Phase 2：新增扁平 FSM

**`fsm_state.gd`（`class_name FsmState extends Node`）**

- 字段：`@export var state_id: String`、`var fsm: Fsm`、`var owner_entity: Node`、
  `var blackboard: Blackboard`。
- `setup(machine: Fsm, entity: Node)`：绑定 `fsm` / `owner_entity` / `blackboard`
  （**不递归**——扁平无子状态）。
- hook：`enter` / `exit` / `update` / `physics_update`（默认空）；
  `handle_command(command) -> bool` 默认 `false`；
  `can_enter` / `can_exit` 默认 `true`。
- `request_transition(target_id, context := {}) -> bool`：`fsm` 非空时
  `return fsm.transition_to(target_id, context)`。

**`fsm.gd`（`class_name Fsm extends StateMachineBase`）**

- `@export var initial_state_id: String = ""`、`@export var auto_start: bool = true`。
- `var current_state: FsmState`、`var previous_id: String`、
  `var last_transition_reason: String`、`var last_failed_transition_reason: String`。
  （`owner_entity` / `blackboard` / 两个信号继承自基类。）
- `_ready()`：`owner_entity = owner`；对每个直接子 `FsmState` 调
  `setup(self, owner_entity)`；`auto_start and initial_state_id != ""` 时
  `transition_to(initial_state_id, {"reason": "initial"})`。
- `_process` / `_physics_process`：仅 `current_state.update/physics_update`。
- `handle_command(command) -> bool`（覆写）：`current_state == null` → `false`，
  否则只交 `current_state.handle_command(command)`（**不冒泡**）。
- `transition_to(target_id, context := {}) -> bool`：
  find → 没找到 `_fail_transition`；同态 noop 返回 `true`；
  `current_state.can_exit` / `target.can_enter` 任一 false → `_fail_transition`；
  否则 `exit` 旧态 → 设 `previous_id` → `enter` 新态 → 设 `current_state` →
  emit `state_changed(from_id, target_id)`。
- `get_current_id()`、`find_state(id)`、`_fail_transition(target_id, reason)`。

所有 class / public 成员补 `##` 注释，风格对齐现有 `hfsm.gd` / `hfsm_state.gd`。

### Phase 3：实体接线层接入基类（启用 FSM 即插即用）

把三处对具体 `StateMachine` 的静态类型改为 `StateMachineBase`，节点名 / 解析逻辑不变：

- `entity_root.gd`：`var state_machine: StateMachine` →
  `var state_machine: StateMachineBase`；`get_state_machine_node() -> StateMachine`
  → `-> StateMachineBase`；`get_node_or_null("StateMachine")` 不变。
- `command_receiver.gd`：`var state_machine: StateMachine = null` →
  `StateMachineBase`。`receive_command` 调 `state_machine.handle_command(...)`
  已是基类契约，无需改。
- `entity_contract.gd`：`get_state_machine(node) -> StateMachine` →
  `-> StateMachineBase`；键 `"state_machine"` → 节点名 `"StateMachine"` 的映射不变。

效果：把 `EntityRoot/StateMachine` 节点的脚本换成 `fsm.gd`（子节点用 `FsmState`），
命令管线即可无改动驱动它。

### Phase 4：测试

- **重命名既有测试引用**：`test_state_machine.gd` 内 `StateMachine` / `State` →
  `Hfsm` / `HfsmState`。文件建议改名 `test/unit/kernel/test_hfsm.gd` 以反映新命名
  （改名后确认 GUT 仍能发现）。同步 `test_gameplay_pipeline_integration.gd`。
- **新增 `test/unit/kernel/test_fsm.gd`**，结构参照现有状态机测试，覆盖：
  初始 `current_state == null`；`transition_to` 设置当前态；`auto_start` 进入初始态；
  转移未知 id 失败并 emit `transition_failed`；同态 noop；`state_changed` 携带正确
  previous/current；`previous_id` 更新；`can_exit` / `can_enter` 阻止转移；
  无激活态 `handle_command` 返回 false；委派当前态命中返回 true；
  **扁平特性**：当前态未消费时整机返回 false（无父冒泡）；`find_state` 命中 / 未命中；
  `enter`/`exit` 调用与 `exit` 先于 `enter`；`update`/`physics_update` 仅作用当前态。
- **新增集成测试**（验证 Phase 3 即插即用）：搭一个 `EntityRoot`，其
  `StateMachine` 节点挂 `Fsm`，经 `CommandReceiver.receive_command` 驱动一次
  FSM 转移，断言命令被消费、状态切换。放入 `test/integration/`。

运行：

```bash
$GODOT --headless --log-file /tmp/mkit_fsm.log -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/kernel/test_fsm.gd -gexit
make ut-kernel     # kernel 套件（含重命名后的 HFSM 测试）
make int           # 集成（含新 FSM 实体接线用例 + 现有管线用例）
```

### Phase 5：文档与生成 API

- `docs/glossary.md`：
  - 「HFSM / StateMachine」条目改为 `Hfsm`，链接 `generated/html/classes/Hfsm.html`。
  - 「State」条目改为 `HfsmState`，链接相应页。
  - 新增 `Fsm`、`FsmState`、`StateMachineBase` 三个条目，并在 HFSM / FSM 条目互相
    交叉说明「需要嵌套用 HFSM，互斥扁平用 FSM」。
- `docs/concepts.md` / `docs/architecture.md`：把 `StateMachine` 散文与图示更新为
  `Hfsm`（并提一句 FSM 选项）；架构图里 `HFSM` 文字补「+ FSM」。
- 生成与校验：

```bash
make docs-api      # 由 ## 注释重生成 doctool XML/HTML：
                   # 旧 State.xml/StateMachine.xml -> HfsmState/Hfsm，
                   # 新增 Fsm/FsmState/StateMachineBase
make docs-check    # 校验注释、API 新鲜度、链接（glossary 链接须指向新页名）、导航
```

不手改 `docs/generated/html/`。

### Phase 6：分层与全量门禁

```bash
make layering      # 确认新文件不引入 addons/mkit -> game 依赖
make check         # layering + docs-check + 全部测试门禁
```

## 受影响文件清单（blast radius）

- 新增：`state_machine_base.gd`、`fsm.gd`、`fsm_state.gd`、`test_fsm.gd`、
  新增 FSM 集成测试文件。
- 改名：`state_machine.gd -> hfsm.gd`、`state.gd -> hfsm_state.gd`、
  `test_state_machine.gd -> test_hfsm.gd`。
- 改类型 / extends：`entity_root.gd`、`command_receiver.gd`、`entity_contract.gd`、
  8 个 `game/entities/states/*_state.gd`、2 个引用 `State` 的测试
  （`test_hfsm.gd`、`test_gameplay_pipeline_integration.gd`）。
- 改 .tscn 脚本路径：`player.tscn`、`field_beast.tscn`、`npc_elder.tscn`。
- 改 `##` 散文：`game_command.gd`、`command_receiver.gd`、`ability_controller.gd`、
  `status_effect_controller.gd`、`room_controller.gd`、`inventory_controller.gd`、
  `equipment_controller.gd`、`entity_root.gd`。
- 文档：`glossary.md`、`concepts.md`、`architecture.md` + 重生成的 `docs/generated/`。

## 风险与注意点

- **import / 类缓存**：新增与改名 `.gd` 后，`.godot` 全局类缓存可能滞后，出现
  "Could not parse global class" 连锁报错。先 `godot --headless --import` 刷新缓存、
  生成 `.gd.uid`，再跑测试。
- **.tscn 引用方式**：实体场景按**脚本路径**（非 uid）引用，改名文件必须同步更新
  3 个 .tscn 的 `ext_resource path`，否则场景加载失败。
- **信号去重**：`Hfsm` / `Fsm` 不能再声明与 `StateMachineBase` 同名的信号，否则
  GDScript 报错；统一用基类信号。
- **doctool 页名变更**：`State.html` / `StateMachine.html` 将不再生成，glossary 等
  所有指向旧页名的链接必须改到 `Hfsm.html` / `HfsmState.html`，否则 `make docs-check`
  链接校验失败。
- **重命名零行为变更**：现有 `test_hfsm.gd`（原 `test_state_machine.gd`）必须全绿，
  作为「重命名未改行为」的回归基线。

## 后续可选工作（不在本期范围）

- `Fsm` 上的数据驱动转移表（声明 `from -> on_command -> to`），减少在每个
  `FsmState.handle_command` 里手写 `match`。
- 提供一个使用 `Fsm` 的 game 示例实体，端到端演示扁平 FSM。

## Progress Tracker

- [x] Phase 0：`state_machine_base.gd`（`StateMachineBase`）+ `##` 注释
- [x] Phase 1：HFSM 重命名（文件 / class_name / extends 基类 / 8 game 状态 /
      3 .tscn / 测试引用 / 散文注释），行为不变
- [x] Phase 2：`fsm.gd`（`Fsm`）+ `fsm_state.gd`（`FsmState`）+ `##` 注释
- [x] Phase 3：`entity_root` / `command_receiver` / `entity_contract` 改 `StateMachineBase`
- [x] Phase 4：`test_hfsm.gd` 全绿（回归）；`test_fsm.gd` 全部用例通过；
      FSM 实体接线集成测试通过；`make ut-kernel` + `make int` 绿
- [x] Phase 5：glossary / concepts / architecture 更新；`make docs-api` 生成新页；
      `make docs-check` 通过（链接指向新页名）
- [x] Phase 6：`make layering` 通过；`make check` 全量绿
- [x] 确认未引入 `addons/mkit/ -> game/` 依赖、未加入具体 game 内容

> 实施说明：blast radius 比计划列举的更大——除 `test_hfsm.gd` /
> `test_gameplay_pipeline_integration.gd` 外，`test/unit/modules/` 下 9 个测试与
> `int_test_helpers.gd` / `test_combat_status_feedback_integration.gd` /
> `test_scene8_full_tour_integration.gd` 也引用 `State` / `StateMachine` 类型，已一并改为
> `Hfsm` / `HfsmState`（节点名字符串 `"StateMachine"` 保持不变）。另外
> `tools/check_runtime_contracts.py` 的 `STATE_MACHINE_SCRIPT` 路径、`docs/pipeline.md`、
> `docs/cookbook/02_player_entity.md`、`docs/readme.md`、`docs/debugging.md` 中指向旧页名/旧类名的
> 链接与引用也已更新，否则 `make check` 的 contract-check / docs-check 链接校验会失败。
