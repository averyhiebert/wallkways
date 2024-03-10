extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_hover_text(text):
	if text == "":
		%hover_text.visible = false
	else:
		%hover_text.visible = true
		%hover_text.text = text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
