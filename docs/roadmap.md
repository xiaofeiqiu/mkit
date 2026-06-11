# 当前限制与后续路线

本文只描述当前代码树已经落地的边界，以及文档系统接下来要收敛的方向。

## 当前实现边界

- `ServiceRegistry` 是唯一 autoload，`GameBootstrap` 注册 kernel 服务，`ModuleBootstrap` 在此基础上追加内置 gameplay module 服务。
- 内置服务通过固定 service id 注册，并可通过 `Mkit` 类型化门面访问；当前没有独立的模块声明文件、拓扑排序加载器或插件式模块依赖解析器。
- `addons/mkit/` 只放 reusable runtime 和 gameplay modules；具体敌人、物品、房间、任务、商店价格等内容属于 `game/` 或项目自己的内容目录。
- 静态内容以 `ContentDefinition` / `ResourceDatabase` 进入 `ContentService`；运行时状态由 service、component、controller、instance、state、result 等对象维护。
- 存档 envelope 以 roots、entities、scopes 为主要结构；需要参与跨场景或跨实体恢复的系统应通过明确 save id、entity id 或 save scope 接入。
- 当前 API 文档来源已经收敛到 `.gd` 的 Godot `##` doc comment；`make docs-api` 使用 Godot doctool XML 派生 `docs/generated/html/` 静态 reference。

## 暂不承诺的能力

- 不承诺 `addons/mkit/` 自动扫描并加载任意第三方模块。
- 不承诺 `game/` 内容可以被复制到 addon 内作为默认规则。
- 不承诺所有 demo UI、音频、VFX 都是最终产品级体验；它们主要用于证明 runtime pipeline 可运行。
- 不承诺生成的 HTML reference 可以手写维护；API 契约必须回写到源码旁的 `##` doc comment。

## 后续路线

1. 继续提高 `##` doc comment 的质量，让 generated reference 更像 API 契约而不是声明清单。
2. 按模块补充更多 cookbook，把 class reference 和使用者工作流连接起来。
3. 在公开 API 改动时保持源码 doc comment、Godot XML、HTML reference 和高层教程同步。

## 维护原则

- 公开行为变更时，先更新源码旁的 `##` doc comment，再运行 `make docs-api` 重新生成 reference。
- 高层教程和 cookbook 描述使用者工作流；class reference 描述 API 契约。
- 文档不能引用未来会删除的临时计划作为前置依赖；必要背景应直接写进当前 docs。
