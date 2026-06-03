# AudioManager

## 概念说明

AudioManager 是音效和音乐播放的轻量管理器。它按 audio_id 查找 AudioStream，播放 SFX/Music，并隔离具体音频节点和 bus 配置。Combat、Inventory 和 Room 不应该直接操作 AudioStreamPlayer；FeedbackSystem 只发出 play_sfx 请求。GameBootstrap 会注册一个 AudioManager 为 `audio` service，使 WorldRouter 等系统按 zone 切换 BGM 时默认可用；游戏侧填充 sfx_map / music_map 即可，或替换为自定义实现。

## 设计目的

把音效和音乐的播放逻辑集中到一个服务节点，使玩法系统只通过 audio_id 请求播放，不需要知道具体的 AudioStream 资源路径或 AudioStreamPlayer 节点，方便统一控制音量和 bus。

## 文件

`res://addons/mkit/modules/ui/audio_manager.gd`

## 字段说明

- **sfx_map**：音效资源表。例：hit、death、pickup 映射到对应 AudioStream。
- **music_map**：音乐资源表。例：main_menu、combat_room 映射到背景音乐。
- **sfx_bus**：音效 bus。例：设置为 SFX 后由音量选项统一控制。
- **music_bus**：音乐 bus。例：设置为 Music 后由设置界面控制。
- **music_player**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name AudioManager
extends Node
@export var sfx_map: Dictionary = {}
@export var music_map: Dictionary = {}
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"
var music_player: AudioStreamPlayer = null
func play_sfx(audio_id: String, volume_db: float = 0.0) -> void
func play_music(music_id: String, fade_seconds: float = 0.0) -> void
func stop_music() -> void
```

## 函数使用场景

- **`play_sfx(audio_id, volume_db)`**：播放一次性音效，创建一个临时 AudioStreamPlayer，播放完成后自动 queue_free。FeedbackSystem 收到 damage_applied 后调用 `audio.play_sfx("hit")`。audio_id 不存在时静默跳过，不影响 gameplay。
- **`play_music(music_id, fade_seconds)`**：切换背景音乐，修改 music_player 的 stream 并 play。RunDirector 进入特殊房间（boss 房）时调用切换主题音乐。
- **`stop_music()`**：停止当前音乐，回到主菜单或 run 结束时调用。

## 使用示例

```gdscript
# 播放音效
$AudioManager.play_sfx("pickup")
$AudioManager.play_sfx("hit", -3.0) # 降低 3dB

# 切换背景音乐
$AudioManager.play_music("combat_room")

# 停止音乐
$AudioManager.stop_music()
```
