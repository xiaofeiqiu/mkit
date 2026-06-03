# AudioManager

## 概念说明

AudioManager 是音效和音乐播放的轻量管理器，也是一个 Saveable。它按 audio_id 查找 AudioStream，播放 SFX/Music，处理背景音乐淡入淡出，并持久化 audio bus 音量设置。Combat、Inventory 和 Room 不应该直接操作 AudioStreamPlayer；FeedbackSystem 只发出 play_sfx 请求。GameBootstrap 会注册一个 AudioManager 为 `audio` service，使 WorldRouter 等系统按 zone 切换 BGM 时默认可用；游戏侧填充 sfx_map / music_map 即可，或替换为自定义实现。

## 设计目的

把音效和音乐的播放逻辑集中到一个服务节点，使玩法系统只通过 audio_id 请求播放，不需要知道具体的 AudioStream 资源路径或 AudioStreamPlayer 节点。音量设置通过 bus 名称管理并随 SaveManager 存取，让设置界面和 zone BGM 切换共享同一个运行时服务。

## 文件

`res://addons/mkit/modules/ui/audio_manager.gd`

## 字段说明

- **sfx_map**：音效资源表。例：hit、death、pickup 映射到对应 AudioStream。
- **music_map**：音乐资源表。例：main_menu、combat_room 映射到背景音乐。
- **sfx_bus**：音效 bus。例：设置为 SFX 后由音量选项统一控制。
- **music_bus**：音乐 bus。例：设置为 Music 后由设置界面控制。
- **music_fade_floor_db**：音乐淡出最低音量。`play_music` 使用 fade 时会降到该值后切换 stream，再淡入到 0dB。
- **music_player**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **current_music_id**：当前播放的音乐 ID。重复请求同一首正在播放的音乐时不会重启。
- **bus_volumes**：已设置成功的 bus 音量表。`to_save_data` 会持久化该表，`from_save_data` 会恢复到 AudioServer。

## 接口

```gdscript
class_name AudioManager
extends Saveable
@export var sfx_map: Dictionary = {}
@export var music_map: Dictionary = {}
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"
@export var music_fade_floor_db: float = -80.0
var music_player: AudioStreamPlayer = null
var current_music_id: String = ""
var bus_volumes: Dictionary = {}
func play_sfx(audio_id: String, volume_db: float = 0.0) -> void
func play_music(music_id: String, fade_seconds: float = 0.0) -> void
func stop_music() -> void
func set_bus_volume(bus: String, db: float) -> bool
func get_bus_volume(bus: String) -> float
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`play_sfx(audio_id, volume_db)`**：播放一次性音效，创建一个临时 AudioStreamPlayer，播放完成后自动 queue_free。FeedbackSystem 收到 damage_applied 后调用 `audio.play_sfx("hit")`。audio_id 不存在时静默跳过，不影响 gameplay。
- **`play_music(music_id, fade_seconds)`**：切换背景音乐。`fade_seconds <= 0` 时立即替换 stream；大于 0 时用 Tween 淡出当前曲目、切换 stream、再淡入。WorldRouter 进入带 `bgm_id` 的 zone 时调用。
- **`stop_music()`**：停止当前音乐，回到主菜单或 run 结束时调用。
- **`set_bus_volume(bus, db)`**：设置指定 AudioServer bus 的音量并记录到 `bus_volumes`。bus 为空或不存在时返回 `false`。
- **`get_bus_volume(bus)`**：读取已记录的 bus 音量；没有记录时回退到 AudioServer 当前值，bus 不存在时返回 0。
- **`to_save_data()` / `from_save_data(data)`**：作为 Saveable 保存和恢复 `bus_volumes`。GameBootstrap 注册的 `audio` service 会被 SaveManager 自动收集。

## 使用示例

```gdscript
# 播放音效
$AudioManager.play_sfx("pickup")
$AudioManager.play_sfx("hit", -3.0) # 降低 3dB

# 切换背景音乐
$AudioManager.play_music("combat_room", 0.5)

# 调整并持久化 bus 音量
$AudioManager.set_bus_volume("Music", -8.0)

# 停止音乐
$AudioManager.stop_music()
```
