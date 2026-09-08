# 主城与战斗原创配乐

2026-09-06。两首完整原创编曲已接入晨铃城样板。旋律、和声、段落与 MIDI 均由本项目编写，乐器通过 GeneralUser GS 2.0.3 采样库和 FluidSynth 渲染；没有使用参考录像或原曲的音频片段。

## 曲目与试听

| 用途 | 曲名 | 长度 / 速度 | 编排 |
|---|---|---|---|
| 安全主城 | 晨铃城·晴日回廊 / Sunlit Promenade | 1:51 / 104 BPM / D 大调 | 12 个声部：长笛、双簧管、单簧管、弦乐、拨奏、竖琴、尼龙吉他、低音提琴、圆号、钟琴、巴松、轻打击乐。木管主题、庭院中段与丰满再现。 |
| 任务及练习副本 | 裂隙交锋 / Against the Closing Gate | 1:47 / 144 BPM / D 小调 | 13 个声部：快速弦乐、小提琴、大提琴、低音提琴、圆号、小号、长号、定音鼓、太鼓、管弦打击乐、管钟、竖琴、少量无词合唱。3+3+2 低音节奏、十六分音符推进、短暂收束与末段加强。 |

- [主城完整试听](original-score/bellwake_city/bellwake_city_preview.mp3)
- [战斗完整试听](original-score/rift_battle/rift_battle_preview.mp3)

试听 MP3 末尾有淡出。游戏使用无淡出的完整 OGG 循环；连续渲染两遍后截取第二遍，保留上一轮乐器释放与混响尾音。声部加入确定性的力度、微小起音时间差与乐句表情变化。按乐器家族调整音量，让主旋律、弦乐、拨弦与打击乐有前后层次；母带用静态增益保留动态。

## 游戏接入

`scripts/music_director.gd` 管理两路播放器。到达主城播放主城曲；进入哥布林任务或元素练习副本时，用 1.6 秒等功率淡化切到战斗曲；回城续播离开时的主城曲位置。城内传送不重启曲目，快速来回切换不会叠加新播放器。

原有 M / 音符按钮与存档静音偏好继续生效。暴击或终极使用现有打击反馈系统短暂压低音乐后恢复。旧 `assets/ambience.wav` 保留为历史素材，已经停止加载。已打开的旧游戏进程需要重新启动；Godot 打开本样板的 `bootstrap.tscn` 后按 F6。

运行时只需 `assets/music/` 的两个 OGG，合计约 5.3 MB，不需要安装音乐制作工具。可编辑 MIDI、每首六组 FLAC 分轨、24-bit / 48 kHz 双声道 WAV 母带、试听 MP3 与渲染报告保存在 `original-score/`，由 `.gdignore` 排除 Godot 导入。音源库也不进入运行时。

## 参考与验收范围

用户指定[法兰城 BGM](https://www.youtube.com/watch?v=Drn1NKi0_2w)为主城参考，[魔力宝贝战斗音乐](https://www.youtube.com/watch?v=8PPlbHdcOb8)为战斗参考，要求乐器丰富、战斗有紧张感。

最早两份 MKV 为静音。后续有效录制：`/Users/dev/Movies/2026-09-06 10-02-09.mp4`（主城 15.85 秒）与 `/Users/dev/Movies/2026-09-06 10-05-03.mp4`（战斗 8.43 秒），均检出非静音的 48 kHz 双声道音频。制作方向依据用户要求制定；本次工具没有完成主观听辨，不能把音轨检测称为听过参考，也不声称已达到原曲制作水准。

母带/编码响度、真峰值与接缝信号测量见各曲 `render-report.json`；主城目标 -18 LUFS，战斗 -17 LUFS，游戏基础增益 -5 dB，为音效保留余量。`tools/verify_music.gd` 在真实样板场景验证任务换曲、回城续播、快速切换、静音、打击压低音乐、原生循环与实际非静音解码混音。技术检查不能替代用户对旋律、音色和紧张感的试听判断。

此次全样板 `tools/verify.py` 还报告三项地图相关失败：出生点到 garden 的路径，以及 waystone 3 / 4 落点可达性。音乐专用集成检查通过；本次音乐修改没有更改地图或寻路逻辑，也不将全样板检查记为通过。

## 重建与验证

工具：FluidSynth、FFmpeg、Python 3（mido、numpy、scipy、soundfile）。本机制作环境 `/tmp/bellwake-music-venv` 不是运行游戏的依赖。在仓库根目录执行：

```sh
/tmp/bellwake-music-venv/bin/python game/whispering_forest/tools/compose_music.py
```

`--score city` / `--score battle` 单独重建；`--finish-only` 复用分轨重新混音。源码保留固定随机种子、显式旋律、和声与分段；MIDI 保存乐器轨名和段落标记。重新生成后由 Godot 编辑器完成资源导入，再运行检查：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://game/whispering_forest/tools/verify_music.gd
```

音源 `vendor/GeneralUser-GS.sf2` 及完整作者授权 `vendor/GeneralUser-GS-LICENSE.txt` 随工程保留。[音源作者仓库](https://github.com/mrbumpy409/GeneralUser-GS) · [FluidSynth 文档](https://www.fluidsynth.org/api/settings_synth.html) · [Godot OGG 循环文档](https://docs.godotengine.org/en/stable/classes/class_audiostreamoggvorbis.html)。
