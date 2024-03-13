extends Node

var InkPlayer = load("res://addons/inkgd/ink_player.gd")

@export var player:CharacterBody3D
@export var HUD:CanvasLayer
@export var starting_scene = ""

#@onready var _ink_player = $InkPlayer
@onready var _ink_player = InkPlayer.new()
@onready var text_target:RichTextLabel = %story_rtf

# Called when the node enters the scene tree for the first time.
func _ready():
	text_target.clear()
	text_target.meta_clicked.connect(_select_choice)
	
	if GlobalStory.player_ready:
		_story_loaded()
	else:
		GlobalStory.player_loaded.connect(_story_loaded)

func start_from(knot):
	if player:
		player.disabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$InkHolder.visible = true
	if HUD:
		HUD.set_hover_text("")
	GlobalStory._ink_player.choose_path(knot)
	GlobalStory._ink_player.continue_story()

func _exit_story_mode():
	# TEMP: disable player
	$InkHolder.visible = false
	if player:
		player.regain_control()

# ############################################################################ #
# Signal Receivers
# ############################################################################ #

func _story_loaded():
	_ink_player = GlobalStory._ink_player
	_ink_player.continued.connect(_continued)
	_ink_player.prompt_choices.connect(_prompt_choices)
	_ink_player.ended.connect(_ended)
	# Set up observers and bind external functions, if desired
	GlobalStory._ink_player.observe_variables(["BLACK_BACKGROUND"],self,"set_background")
	if player:
		GlobalStory._ink_player.bind_external_function("player_upright", player, "is_upright")
	
	if starting_scene != "":
		start_from(starting_scene)

func set_background(name, new_value):
	$InkHolder/black_backround.visible = new_value

func _continued(text, tags):
	
	if "CLEAR" in tags:
		# Clear before next line.
		text_target.clear()
	for tag in tags:
		if tag.begins_with("AUDIO:"):
			# TODO
			var sound_name = tag.split(" ")[1]
	text = text.replace("<br>","\n")
	text_target.append_text(text)
	
	if _ink_player.can_continue or _ink_player.has_choices or true:
		_ink_player.continue_story()
	else:
		_exit_story_mode()


# ############################################################################ #
# Private Methods
# ############################################################################ #

func _prompt_choices(choices):
	if !choices.is_empty():
		var index = 0
		for choice in choices:
			if not (choice.text.begins_with("DEBUG")):
				text_target.append_text("\n[center][url=%d]%s[/url][/center]" % [index, choice.text])
			index += 1


func _ended():
	_exit_story_mode()
	print("The End")

func _select_choice(index):
	# Note: clear after each choice, to fit with blink theme
	text_target.clear()
	_ink_player.choose_choice_index(int(index))
	_ink_player.continue_story()


# Uncomment to bind an external function.
#
func _bind_externals():
	_ink_player.bind_external_function("squared", self, "_external_function")
#
#
func _external_function(arg1):
	return arg1*arg1


# Uncomment to observe the variables from your ink story.
# You can observe multiple variables by putting adding them in the array.
# func _observe_variables():
# 	_ink_player.observe_variables(["var1", "var2"], self, "_variable_changed")
#
#
# func _variable_changed(variable_name, new_value):
# 	print("Variable '%s' changed to: %s" %[variable_name, new_value])

