extends RefCounted

const Sculpt = preload("res://game/whispering_forest/art/characters/mage_sculpt.gd")
const TIP := Vector3(0,1.45,0)
const FOOT := Vector3(0,-0.86,0)

func rebuild(parent: Node3D, rig: Node3D) -> void:
	for child in parent.get_children(): child.free()
	var sculpt := Sculpt.new()
	sculpt.r=rig
	var wood := sculpt.surface("423843")
	var grain := sculpt.surface("746051")
	var leather := sculpt.surface("292d3b")
	var gold := sculpt.surface("c7a56b",0.72,0.18)
	var gold_light := sculpt.surface("e2c68d",0.65,0.18)
	var gem := sculpt.surface("48aeb6",0.68,0.05)
	# One full-length staff, with a ferrule near the floor and a crown above
	# the shoulder. Local +Y is up; this is never aimed like a short wand.
	sculpt.loft(parent,[[-0.86,0.028,0.029,0],[-0.81,0.041,0.040,0],[-0.64,0.039,0.038,0],[-0.26,0.040,0.039,0.006],[0.10,0.047,0.043,0],[0.56,0.054,0.045,0.012],[0.90,0.060,0.050,0],[1.04,0.070,0.057,0]],wood,"FullLengthAshwoodShaft",16)
	sculpt.loft(parent,[[-0.86,0.028,0.028,0],[-0.82,0.047,0.047,0],[-0.73,0.047,0.047,0],[-0.70,0.041,0.041,0]],gold,"GroundFerrule",12)
	sculpt.loft(parent,[[-0.12,0.052,0.050,0],[0.13,0.052,0.050,0]],leather,"PalmGrip",16)
	for y in [-0.13,0.14,0.67,0.96]:
		sculpt.loft(parent,[[y-0.016,0.060,0.058,0],[y+0.016,0.060,0.058,0]],gold,"StaffBand",12)
	for side in [-1.0,1.0]:
		sculpt.tube(parent,[Vector3(side*0.018,-0.64,0.036),Vector3(side*0.012,0.18,0.044),Vector3(side*0.03,0.68,0.045),Vector3(side*0.02,0.88,0.050)],[0.004,0.005,0.007,0.004],0.5,grain,"WoodInlay",6)
	# Crown forks around a tall cut crystal; warm metal defines the silhouette.
	for side in [-1.0,1.0]:
		sculpt.tube(parent,[Vector3(side*0.025,0.92,0),Vector3(side*0.17,1.04,0),Vector3(side*0.19,1.22,0),Vector3(side*0.08,1.39,0)],[0.043,0.040,0.031,0.010],0.75,gold_light,"CrownFork",10)
	sculpt.loft(parent,[[1.02,0.025,0.025,0],[1.10,0.13,0.093,0],[1.29,0.115,0.079,0],[1.45,0.002,0.002,0]],gem,"UprightAetherCrystal",6)
	sculpt.loft(parent,[[0.98,0.07,0.061,0],[1.04,0.10,0.068,0],[1.07,0.045,0.042,0]],gold,"CrystalSocket",10)
	# A small cloth knot moves with the staff, without dangling into the face.
	sculpt.patch(parent,[Vector3(0.08,0.83,0),Vector3(0.16,0.76,0),Vector3(0.12,0.47,-0.03),Vector3(0.065,0.57,-0.015)],sculpt.surface("e9dbc0"),"StaffBindingRibbon")
