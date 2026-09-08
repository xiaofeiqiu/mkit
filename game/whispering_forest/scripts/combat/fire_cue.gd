extends RefCounted

# One source of truth for the L1 blast's sound, hit, eight poses and endpoint.
# Imported WAV duration includes its quiet closing tail; no guessed timer or
# randomized pitch may let the image outlive that audio.
const PATH := "res://game/whispering_forest/assets/fire-audio-v5/fire-level-1.wav"
const STREAM := preload("res://game/whispering_forest/assets/fire-audio-v5/fire-level-1.wav")
const POSE_FRACTIONS := [0.0,0.035,0.085,0.16,0.30,0.47,0.69,1.0]

static func duration() -> float:
	return STREAM.get_length()

static func hit_time() -> float:
	return duration()*POSE_FRACTIONS[2]

static func pose_times() -> Array:
	var result: Array=[]
	for fraction in POSE_FRACTIONS: result.append(float(fraction)*duration())
	return result
