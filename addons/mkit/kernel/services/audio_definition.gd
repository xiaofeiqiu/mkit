class_name AudioDefinition
extends ContentDefinition
## 说明：`AudioDefinition` 是 基础服务 的静态内容定义，负责描述可被 ContentService 注册和查找的资源数据。
## 上游：通常由 ResourceDatabase、ContentService 和编辑器资源配置创建或调用。
## 下游：会连接领域服务、controller、effect 或生成器，不直接依赖具体游戏内容。
## 使用：当项目需要用资源配置可复用内容，而不是把具体数值写死在代码里时使用它。
## 示例：在 ResourceDatabase 中加入 `AudioDefinition` 资源，再通过 ContentService 按 id 查询。


## 公开枚举 `AudioKind`，限定 `AudioDefinition` 可接受的配置或运行时状态取值。
enum AudioKind { SFX, MUSIC }

## 公开常量 `TYPE_NAME`，作为 `AudioDefinition` 对外暴露的类型、事件或命令标识。
const TYPE_NAME := "AudioDefinition"

## ContentService 注册音频资源时使用的稳定 id；AudioService 播放音效或音乐时按它查找。
@export var audio_id: String = ""
## 要播放的音频流资源；为 null 时 AudioService 会跳过播放请求。
@export var stream: AudioStream = null
## 音频分类；决定默认播放通道和一次性/音乐类处理方式。
@export var kind: AudioKind = AudioKind.SFX
## 是否循环播放该音频；通常只对音乐或环境声开启。
@export var loop: bool = false


## 返回 ContentService 用于注册和查找的稳定内容 id，并保持 `AudioDefinition` 的领域契约一致。
func get_content_id() -> String:
	return audio_id
