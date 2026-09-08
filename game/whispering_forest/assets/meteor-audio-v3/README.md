# 陨石声音 v3

2026-09-06。依据用户提供的十级参考 `陨石1.wav`（1.13 秒）和 `陨石2.wav`（1.37 秒），重做一级、十级土系陨石及火陨终极的下落与撞击声。参考用于分析包络、频段与重量表现；运行时没有混入参考 WAV 的采样。

## 已接入的声音

| 文件 | 使用场景 | 设计 |
|---|---|---|
| `fall-small.wav` | 一级至五级下落，0.95 秒 | 逐渐靠近的风声、很轻的石屑，减少低频 |
| `rock-small.wav` | 一级至五级命中，1.10 秒 | 清晰的石头撞击起音、短促低频、少量碎石和短尾音 |
| `fall-full.wav` | 六级至十级下落，0.95 秒 | 更强、更宽频段的风啸，增加低频空气压力与石屑 |
| `rock-full.wav` | 六级至十级命中，1.50 秒 | 硬起音、石体中低频共鸣、低沉撞击、滚动碎石和更长余响 |
| `ultimate-fall-full.wav` | 火陨终极下落，1.05 秒 | 独立的风啸层＋火焰轰鸣层＋细碎燃烧声＋石屑 |
| `ultimate-impact-full.wav` | 火陨终极命中，2.15 秒 | 重击、低频冲击、碎石和余焰燃烧 |

全部为 48kHz、16-bit、立体声 PCM。`manifest.json` 记录音量、时长、分层和哈希。等级还会影响游戏内音量和轻微音高；一级与十级的层数、包络和余响不同，并非只改变音量。

## 游戏事件

`scripts/combat/spell_system.gd` 的 `sound_path()` 为上述事件选择新音库，其他魔法及结印声继续使用 `spell-audio-v2`。

普通陨石在每颗生成时开始风声，0.95 秒后碰地才播放撞击。当前多重陨石与其他元素统一在默认 0.8 秒窗口内依次释放：十级四颗约每 0.267 秒一颗，五颗每 0.2 秒一颗。每颗都有完整风声和撞击声；多重数增加时适当衰减各层，继续使用已有 WF Impact 限制器。终极保留 1.3 秒结印流程，第 0.25 秒开始风火下落混音，第 1.3 秒播放重击。

## 编辑与来源

- 可重新生成：`tools/make_meteor_audio_v3.py`。只写本目录和本轮音轨/试听文件，不重写其他技能声音。
- 独立风、火、冲击、低频和碎石音轨：`art/audio/meteor-v3/`。它们是编辑源，不额外占用游戏声音通道。
- 原创滤波风声、火焰轰鸣/爆裂、冲击与共鸣，叠加项目已有的 Kenney CC0 `impactMining_*`、`impactSoft_heavy_001` 和 `cloth1` 录音。原始许可位于 `art/impact-sources/impact/License.txt` 和 `art/impact-sources/rpg/License.txt`。
- 参考文件保持原样；特征分析和哈希在 manifest 中，重新生成不要求参考文件一直留在 Downloads。

## 验证与试听

- `tools/verify_meteor_audio.py` 检查六个文件格式、端点、无削波、风声渐强、即时打击起音、等级强弱/尾音差异，以及终极风与火音轨非空且具有有效能量。结果：`preview/meteor-audio-v3-verification.json`。
- 战斗回归验证一级音库选择、十级四次下落/四次撞击及各自时机，终极选择风火混音，回城重置后清理音频事件。
- `--wf-combat-review --wf-meteor-audio` 录制一级、十级和终极实机片段；事件日志保存为 `preview/meteor-audio-v3-events.json`。
- 可直接试听 `preview/meteor-level-1-v3.wav`、`meteor-level-10-v3.wav`、`ultimate-meteor-v3.wav`。这些 v3 试听和 `preview/meteor-audio-v3.mp4` 保留当时四颗按 0.18 秒间隔的历史节奏；最新统一释放时序见 `preview/volley-v7.mp4`，单颗声音素材不变。

技术验证不等于听感验收；参考中的重量、风火比例和打击感需结合实际播放评估。
