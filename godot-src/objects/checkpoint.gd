extends Node3D

@export var index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Clickable.knot = "checkpoint" + str(index)
