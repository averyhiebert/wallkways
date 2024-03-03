extends CharacterBody3D


const SPEED = 5.0
#const JUMP_VELOCITY = 4.5
const JUMP_VELOCITY = 10
const GRAVITY_MULTIPLIER = 2
const FALL_GRAVITY_MULTIPLIER = 3
const TERMINAL_VELOCITY = 10
const ROTATION_TIME_MS = 250
const COYOTE_TIME_MS = 200

var mouse_sensitivity = 0.002

# rotation stuff
var rotate_from = Basis()
var rotate_to = Basis()
var physics_basis = Basis()
var rotation_percentage = 1.0
var last_rotated = 0 # Last time we rotated, used for lockout
var last_jumped = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	physics_basis = transform.basis
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # uncapture mouse
	if event.is_action_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Note: so far just copied from 
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not currently_rotating():
		rotate_object_local(Vector3(0,1,0),-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_object_local(Vector3(1,0,0),-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

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
	return (Time.get_ticks_msec() - last_jumped) > COYOTE_TIME_MS

func _physics_process(delta):
	slerp_rotation(delta)
	
	var local_velocity = physics_basis.inverse() * velocity
	
	
	# Add the gravity and/or start new rotation
	if is_on_floor():
		var normal = get_floor_normal()
		var angle = normal.angle_to(transform.basis[1])
		if (abs(angle - deg_to_rad(45)) < 0.00001) and not currently_rotating():
			var axis = get_floor_normal().cross(transform.basis[1]).normalized()
			var new_transform = transform.rotated(axis,-angle)
			
			# TODO Interpolate w/ quaternions
			#transform.basis = new_transform.basis
			start_rotation(transform.basis.orthonormalized(),new_transform.basis.orthonormalized())
			
			up_direction = get_floor_normal() # For correct floor detection
			last_rotated = Time.get_ticks_msec()
			local_velocity.y = 0
	elif local_velocity.y > 0:
		local_velocity.y -= GRAVITY_MULTIPLIER * gravity * delta
	else:
		# Fall slightly faster after the peak of the jump (less floaty)
		local_velocity.y -= FALL_GRAVITY_MULTIPLIER * gravity * delta
		#local_velocity.y = clamp(local_velocity.y,-TERMINAL_VELOCITY,TERMINAL_VELOCITY)
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_time()):
		local_velocity.y = JUMP_VELOCITY
		last_jumped = Time.get_ticks_msec()

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
