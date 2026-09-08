# 人物制作与动作审阅

当前规格与实机证据见 [Character Production.md](Character%20Production.md)。玩家为日漫奇幻风格、深蓝分层短发的八方向动态角色，竖握长法杖；正常走跑已修正重复弹跳并保持视线稳定。导师 NPC 固定站姿。正式素材目录为 `assets/characters/world-motion/`，运行时由 `scripts/combat/performance_frames.gd` 加载。

正式重建命令（仓库根目录、图形环境）：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-method forward_plus --script res://game/whispering_forest/tools/bake_world_characters.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
```

运行 `animation_studio.tscn` 可审阅当前动作，数字 1–6 切换动作，Tab 换角色。共享相机和灯光由 `art/city/render_config.gd` 定义，不能使用下方历史导出命令覆盖正式目录。

## 历史记录：Character Motion v0.4（以下不是当前规格）

2026-09-06。根据用户提供的两张人物参考，重做为约3头身的简洁立体角色：宽而清楚的色块、可读的头胸四肢、少量发束、固定日光和细轮廓。玩家采用原创红棕短发、蓝短袍、浅色围巾与右手法杖；梅尔保留灰发、紫衣、导师身份；哥布林保留绿皮、尖帽与木棒。

本轮源资产是`character_rig.gd`中的可编辑3D关节模型与动作参数，由Godot正交渲染为透明序列。环境继续使用独立素材拼装。参考截图用于体块、头身比和动作阅读，不提取其中人物像素。

## 已交付

| 角色 | 八向待机 | 八向行走 | 八向攻击 | 八向结印 |
|---|---:|---:|---:|---:|
| 玩家法师 | 8帧/向 | 8帧/向 | 8帧/向 | 8帧/向 |
| 导师梅尔 | 8帧/向 | 8帧/向 | 8帧/向 | 8帧/向 |
| 哥布林（精英复用） | 8帧/向 | 8帧/向 | 8帧/向 | 8帧/向 |

总计12张2048×2048图集、768个256×256帧单元。每行一个朝向，行序为S、SW、W、NW、N、NE、E、SE；每行从左到右是8帧。每个人物从同一个模型渲染全部方向，法杖/木棒持续留在右手。梅尔在主城使用待机与转向，行走/攻击资源为后续演出预备；哥布林当前战斗使用待机/行走/攻击，结印资源是通用制作流程的预备态，不增加哥布林魔法技能。

步态包括：支撑段与摆动段、抬脚/落脚、膝部弯曲、脚跟先落与脚尖离地、髋部重心、肩胸反向转动、摆臂、围巾和衣摆滞后。待机包含轻呼吸、头部微动和短眨眼；普通攻击抬臂，法师终极把法杖收在背后，双手收于胸前结印。

## 接入方式

- `scripts/character_frames.gd`缓存图集区域与轮廓材质；每个帧单元的地面原点为(128,218)。
- `scripts/actor.gd`按屏幕移动方向选八向，按实际位移推进步态；停步或被碰撞挡住时回待机。角色本体不作整图摇摆。
- 对话期间玩家与梅尔继续待机，战斗与移动仍暂停。施法、碰撞、任务、传送和保存沿用现有逻辑。
- 人形显示身高约72px，普通/精英哥布林约56/74px。头像也更新为同一个角色。
- 细轮廓由`assets/characters/outline.gdshader`在运行时绘制。图集本身保留RGBA透明边界。

## 预览与重建

双击样板目录中的`Character Animation Studio.command`，可同时看八个方向，并切换人物、待机/行走/攻击/结印。支持中英、鼠标操作及1–4动作、Tab人物、空格暂停。城市仍从`晨铃城样板.app`启动。

```sh
# 在仓库根目录运行；需要图形渲染环境。
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-method gl_compatibility --script res://game/whispering_forest/tools/bake_characters.gd
# 烘焙后重新导入，再运行原样板。
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import
make forest-test
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://game/whispering_forest/tools/verify_characters.gd
```

烘焙器在换姿态后等待完整渲染帧，防止下一行首帧误取上一朝向。当前检查覆盖768帧的非空、透明背景、边缘完整性，以及每个方向8个不同的行走姿态。游戏检查覆盖八向输入、动画推进、固定脚底点、停步、碰撞阻挡和原有任务流程。

3D源模型通过Godot的[SubViewport渲染流程](https://github.com/godotengine/godot-docs/blob/master/tutorials/rendering/viewports.rst)输出，造型中的发束使用[SurfaceTool](https://docs.godotengine.org/zh-cn/4.x/classes/class_surfacetool.html)构建；游戏运行时加载已烘焙的2D帧。

## 当前边界

这是一版可修改的人物造型与动作样板。还需做正式受击、闪避、倒地、拾取与更多NPC表情/交互；没有把这些算作已完成。动作采用关节分段模型，衣服边缘、肢体连接和收杖过渡仍可进一步修形；环境建筑与树木暂沿用上一版，尚未完成全场景的统一笔触修订。

本机Godot4.7.dev5的离线3D烘焙在退出时报告两个GLES3纹理释放警告（约153KB）；输出完成并通过逐帧检查。该警告保留在`preview/character-bake.log`作为工具链问题记录，2D角色预览和正常游戏分别验证。
