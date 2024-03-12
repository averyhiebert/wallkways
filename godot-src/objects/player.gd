extends CharacterBody3D

signal clicked_item(knot)

const SPEED = 5.0
const JUMP_VELOCITY = 10
const GRAVITY_MULTIPLIER = 2
const FALL_GRAVITY_MULTIPLIER = 3
const TERMINAL_VELOCITY = 10
const ROTATION_TIME_MS = 200
const COYOTE_TIME_MS = 200

var mouse_sensitivity = 0.002
# Possible range: 0.0001 - 0.01?
var invert_x_factor = 1 #-1 for inverted
var invert_y_factor = 1
var fov = 75

var disabled = false # Used to turn off player control during text etc.

# rotation stuff
var rotate_from = Basis()
var rotate_to = Basis()
var physics_basis = Basis()
var rotation_percentage = 1.0
var last_rotated = 0 # Last time we rotated, used for lockout
var last_jumped = 0
var last_on_floor = 0

# Clicking stuff
var current_clickable = null
@export var HUD: CanvasLayer = null
@export var pause_menu: CanvasLayer = null
@export var spawn_points:Array[Node3D] = []

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	physics_basis = transform.basis
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if GlobalStory.player_ready:
		_bind_ink_external()
	else:
		GlobalStory.player_loaded.connect(_bind_ink_external)

func _bind_ink_external():
	GlobalStory._ink_player.bind_external_function("player_upright", self, "is_upright")
	
func is_upright():
	return (up_direction - Vector3(0,1,0)).length() < 0.001

func _input(event):
	if disabled:
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # uncapture mouse
		disabled = true
		pause_menu.visible = true
	
	# Note: so far just copied from 
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not currently_rotating():
		rotate_object_local(Vector3(0,1,0),-event.relative.x * mouse_sensitivity * invert_x_factor)
		$Camera3D.rotate_object_local(Vector3(1,0,0),-event.relative.y * mouse_sensitivity * invert_y_factor)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func regain_control():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	disabled = false

func rotate_cooldown():
	return not (Time.get_ticks_msec() - last_rotated) > ROTATION_TIME_MS

func start_rotation(from,to):
	print("Started rotation")
	rotation_percentage = 0
	rotate_from = from
	rotate_to = to
	physics_basis = rotate_to

func currently_rotating():
	return rotation_percentage < 1

func slerp_rotation(delta):
	# Note: control directions will be a little off while rotating.
	if currently_rotating():
		rotation_percentage += (delta*1000.0) / ROTATION_TIME_MS
		rotation_percentage = clamp(rotation_percentage,0.0,1.0)
		transform.basis = rotate_from.slerp(rotate_to,rotation_percentage)
		#print((delta*1000.0) / ROTATION_TIME_MS)
	else:
		if physics_basis != transform.basis:
			# Update physics basis to match any camera rotations etc.
			physics_basis = transform.basis

func avoid_wall_slipping(local_velocity):
	# If this retursn true, we disable x/z player movement to avoid weird behaviour.
	#  Kinda janky, will have to find a better way later.
	return is_on_wall() and not is_on_floor() and abs(local_velocity.y) < 5

func coyote_time():
	return (Time.get_ticks_msec() - last_on_floor) < COYOTE_TIME_MS

func jump_timeout():
	return (Time.get_ticks_msec() - last_jumped) < COYOTE_TIME_MS + 1

func check_clickable():
	var raycast = %RayCast3D
	if raycast.is_colliding() and raycast.get_collider() is Clickable:
		var collider = raycast.get_collider()
		if current_clickable != collider:
			current_clickable = collider
			HUD.set_hover_text(current_clickable.hover_text)
	elif current_clickable:
		current_clickable = null
		print("No more clickable")
		HUD.set_hover_text("")
	
	if Input.is_action_just_pressed("click") and current_clickable:
		clicked_item.emit(current_clickable.knot)

func respawn():
	var i = GlobalStory._ink_player.evaluate_function("respawn").return_value;
	var spawn_point = spawn_points[i]
	disabled = false
	velocity = Vector3(0,0,0)
	global_transform = spawn_point.global_transform
	global_transform.basis = spawn_point.global_transform.basis
	rotate_from = transform.basis
	rotate_to = transform.basis
	physics_basis = transform.basis
	rotation_percentage = 1.0
	up_direction = Vector3(0,1,0)

func _physics_process(delta):
	slerp_rotation(delta)
	
	# Update camera FOV if necessary
	$Camera3D.fov = fov
	if disabled:
		return
	
	if Input.is_action_just_released("respawn"):
		respawn()
		return
	
	var local_velocity = physics_basis.inverse() * velocity
	
	check_clickable()
	
	# Add the gravity and/or start new rotation
	if is_on_floor():
		var normal = get_floor_normal()
		var angle = normal.angle_to(transform.basis[1])
		if (abs(angle - deg_to_rad(45)) < 0.005) and not currently_rotating():
			var axis = get_floor_normal().cross(transform.basis[1]).normalized()
			var new_transform = transform.rotated(axis,-angle)
			
			# TODO Interpolate w/ quaternions
			#transform.basis = new_transform.basis
			start_rotation(transform.basis.orthonormalized(),new_transform.basis.orthonormalized())
			
			up_direction = get_floor_normal() # For correct floor detection
			last_rotated = Time.get_ticks_msec()
			local_velocity.y = 0
		last_on_floor = Time.get_ticks_msec()
	elif local_velocity.y > 0:
		local_velocity.y -= GRAVITY_MULTIPLIER * gravity * delta
	else:
		# Fall slightly faster after the peak of the jump (less floaty)
		local_velocity.y -= FALL_GRAVITY_MULTIPLIER * gravity * delta
		#local_velocity.y = clamp(local_velocity.y,-TERMINAL_VELOCITY,TERMINAL_VELOCITY)
	
	# Handle jump.
	if Input.is_action_pressed("jump") and (is_on_floor() or coyote_time()) and not jump_timeout():
		local_velocity.y = JUMP_VELOCITY
		last_jumped = Time.get_ticks_msec()
	
	if Input.is_action_just_pressed("flashlight"):
		%flashlight.visible = !%flashlight.visible

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left","right","forward","back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	#if direction and not (is_on_wall() and not is_on_floor()):
	if direction and not avoid_wall_slipping(local_velocity):
		local_velocity.x = direction.x * SPEED
		local_velocity.z = direction.z * SPEED
	else:
		local_velocity.x = move_toward(local_velocity.x, 0, SPEED)
		local_velocity.z = move_toward(local_velocity.z, 0, SPEED)
	
	#velocity = transform.basis * local_velocity
	velocity = physics_basis * local_velocity
	

	
	move_and_slide()


func _on_death_zone_body_exited(body):
	respawn()
