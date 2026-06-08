class_name AudioDefinition
extends ContentDefinition

enum AudioKind { SFX, MUSIC }

const TYPE_NAME := "audio_definition"

@export var audio_id: String = ""
@export var stream: AudioStream = null
@export var kind: AudioKind = AudioKind.SFX
@export var loop: bool = false


func get_content_id() -> String:
	return audio_id
