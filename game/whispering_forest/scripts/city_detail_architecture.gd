@tool
extends "res://game/whispering_forest/scripts/architecture.gd"

func _ready() -> void:
	super._ready()
	masonry=load("res://game/whispering_forest/assets/city-detail/masonry.png")
	wall_height=132
	queue_redraw()

func wall(axis: Vector2) -> void:
	var size := Vector2(length,38) if axis.x>0 else Vector2(38,length)
	var rect := Rect2(-size*0.5,size)
	box(rect.grow(4),12,0,Color(0.90,0.95,0.97))
	box(rect,wall_height-10,0,Color(0.98,1.0,1.02))
	box(rect.grow(2),6,wall_height-13)
	# A visible wall walk between two narrow parapets, rather than a solid cap.
	for side in [-1,1]:
		var rail := Rect2(-length/2,side*15-4,length,8) if axis.x>0 else Rect2(side*15-4,-length/2,8,length)
		box(rail,15,wall_height-10,Color(0.96,0.98,1.0))
		var count := maxi(2,int(length/30))
		for i in range(count):
			var at := axis*((i+0.5)*length/count-length/2)+Vector2(-axis.y,axis.x)*side*15
			var merlon := Vector2(15,9) if axis.x>0 else Vector2(9,15)
			box(Rect2(at-merlon/2,merlon),16,wall_height+4)
			box(Rect2(at-merlon/2,merlon).grow(1),2,wall_height+20)
	var buttress := Vector2(18,43) if axis.x>0 else Vector2(43,18)
	box(Rect2(-buttress/2,buttress),wall_height-30,0,Color(0.91,0.95,0.95))

func face(a: Vector2,b: Vector2,low: float,high: float,tint: Color) -> void:
	super.face(a,b,low,high,tint)
	if high-low<50: return
	# Localized dampness and runoff at masonry joints, not uniform dirt noise.
	var seed_value := posmod(roundi(ground.x*3+ground.y*7+a.x+a.y),11)
	for i in range(2):
		var t := 0.22+i*0.42+seed_value*0.012
		var p := point(a.lerp(b,t),high-4)
		draw_line(p,p+Vector2(0,10+seed_value),Color(0.24,0.28,0.27,0.13),2.3,true)
	if low<1:
		var p1 := point(a,3)
		var p2 := point(b,3)
		draw_line(p1,p2,Color(0.25,0.34,0.27,0.23),4,true)
