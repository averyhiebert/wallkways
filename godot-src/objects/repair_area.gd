extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_body_entered(body):
	# Don't need to check that body is player, it's the only thing in layer 3
	GlobalStory._ink_player.set_variable("can_repair",true)

func _on_body_exited(body):
	GlobalStory._ink_player.set_variable("can_repair",false)
