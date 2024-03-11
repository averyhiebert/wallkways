extends Node3D

@export var index:int

# Called when the node enters the scene tree for the first time.
func _ready():
	$Clickable.knot = "antenna_mast" + str(index)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
