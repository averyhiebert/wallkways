extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var mouse_sensitivity = 0.002

const ROTATE_COOLDOWN_TIME_MS = 500 # in ms, how long before we can rotate again
var last_rotated = 0 # Last time we rotated, used for lockout

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # uncapture mouse
		# TODO Also recapture on mouse click
	
	# Note: so far just copied from 
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_object_local(Vector3(0,1,0),-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_object_local(Vector3(1,0,0),-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func rotate_cooldown():
	return not (Time.get_ticks_msec() - last_rotated) > ROTATE_COOLDOWN_TIME_MS

func _physics_process(delta):
	var local_velocity = transform.basis.inverse() * velocity
	
	# Add the gravity.
	if is_on_floor():
		var normal = get_floor_normal()
		var angle = normal.angle_to(transform.basis[1])
		if (abs(angle - deg_to_rad(45)) < 0.00001) and not rotate_cooldown():
			print("rotating")
			var axis = get_floor_normal().cross(transform.basis[1]).normalized()
			var new_transform = transform.rotated(axis,-angle)
			
			# TODO Interpolate w/ quaternions
			transform.basis = new_transform.basis
			
			up_direction = get_floor_normal() # For correct floor detection
			last_rotated = Time.get_ticks_msec()
			local_velocity.y = 0
	else:
		local_velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		local_velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left","right","forward","back")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		local_velocity.x = direction.x * SPEED
		local_velocity.z = direction.z * SPEED
	else:
		local_velocity.x = move_toward(velocity.x, 0, SPEED)
		local_velocity.z = move_toward(velocity.z, 0, SPEED)
	
	velocity = transform.basis * local_velocity
	
	move_and_slide()
