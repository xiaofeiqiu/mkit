extends RefCounted

# Steering is continuous in ground space. Random choices happen at the end of a
# movement phrase, never every frame, so the vortex roams without jittering.
var rng := RandomNumberGenerator.new()
var mode := "straight"
var remaining := 0.8
var turn_rate := 0.0
var desired_rate := 0.0
var speed := 105.0
var desired_speed := 105.0
var phrases: Array[String] = []
var history: Array[String] = ["straight"]

func _init(seed_value: int = 0) -> void:
	rng.seed=seed_value
	remaining=rng.randf_range(0.65,0.95)

func advance(direction: Vector2, delta: float) -> Vector2:
	remaining-=delta
	if remaining<=0: next_phrase()
	turn_rate=move_toward(turn_rate,desired_rate,delta*7.0)
	speed=move_toward(speed,desired_speed,delta*70.0)
	return direction.rotated(turn_rate*delta).normalized()

func next_phrase() -> void:
	if phrases.is_empty():
		# Every cycle contains all three behaviors, with randomized order, length,
		# handedness and curvature. Multiple tornadoes own independent RNGs.
		phrases.assign(["turn","orbit","straight"])
		for i in range(phrases.size()-1,0,-1):
			var j:=rng.randi_range(0,i)
			var swap:=phrases[i]
			phrases[i]=phrases[j]; phrases[j]=swap
	var next: String=phrases.pop_front()
	if next==mode and not phrases.is_empty():
		phrases.append(next)
		next=phrases.pop_front()
	set_phrase(next,1.0 if rng.randf()>0.5 else -1.0)

func set_phrase(value: String, handedness: float = 1.0) -> void:
	mode=value
	history.append(mode)
	if history.size()>12: history.pop_front()
	match mode:
		"straight":
			desired_rate=0
			remaining=rng.randf_range(0.75,1.25)
			desired_speed=rng.randf_range(100,115)
		"turn":
			desired_rate=handedness*rng.randf_range(0.65,1.10)
			remaining=rng.randf_range(0.9,1.4)
			desired_speed=rng.randf_range(90,105)
		"orbit":
			desired_rate=handedness*rng.randf_range(1.8,2.2)
			remaining=TAU/absf(desired_rate)+0.25
			desired_speed=rng.randf_range(88,102)

func on_bounce() -> void:
	# Let the reflected path clear the surface before resuming random steering.
	mode="straight"
	remaining=0.38
	turn_rate=0
	desired_rate=0
