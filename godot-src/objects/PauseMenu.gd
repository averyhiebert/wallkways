extends CanvasLayer

@export var player: CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_fullscreen_button_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_fov_slider_value_changed(value):
	player.fov = value


func _on_invert_y_button_toggled(toggled_on):
	player.invert_y_factor = -1 if toggled_on else 1


func _on_invert_x_button_toggled(toggled_on):
	player.invert_x_factor = -1 if toggled_on else 1


func _on_mouse_sensitivity_slider_value_changed(value):
	player.mouse_sensitivity = value * 0.0001


func _on_exit_menu_pressed():
	visible = false
	player.regain_control()
