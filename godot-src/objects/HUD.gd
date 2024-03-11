extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	if GlobalStory.player_ready:
		_observe_variables()
	else:
		GlobalStory.player_loaded.connect(_observe_variables)

func set_hover_text(text):
	if text == "":
		%hover_text.visible = false
	else:
		%hover_text.visible = true
		%hover_text.text = text

func _observe_variables():
	print("Observerwas called")
	GlobalStory._ink_player.observe_variables(["total_repaired"],self,"_update_counter")

func _update_counter(name,value):
	print("Should update counter now?")
	%progress_tracker.text = str(value) + "/3"
