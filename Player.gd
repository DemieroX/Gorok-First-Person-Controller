# Gorok - Retro First Person Controller
# This is one of the first things I have coded in Godot so forgive my horrible code
# Few people asked for the source code of the project and I decided to release it
# Feel free to use it on any of your projects, credit is appreciated :D

extends CharacterBody3D

var hp = 100 # Player health variable

# Movement variables
const speed = 9.36
var current_speed = 0.0  # Tracks the player's current speed
var spawn_point = Vector3.ZERO  # Stores the player's saved position

# Bunny hop variables
const bunny_hop_speed_cap = 30.0  # Cap for the maximum speed during bhopping
const bunny_hop_speed_increase = 1.12  # Factor to increase speed /per jump
var allow_bhop = true  # Enable/disable bunny hopping
var bhop_speed = speed  # Initialize to base speed
var on_ground_time = 0.0  # Time spent on the ground
var was_in_air = false  # Check if player is mid-air

# Jump variables
const jump_velocity = 7.75 # Strength of base jump speed
const time_to_reset_speed = 0.2  # Time to wait before resetting speed
const fall_reset_y = -80.0  # Y position threshold for resetting player position

# Ramp jump variables
const ramp_jump_multiplier = 2.0  # Increase this for more jump height on ramps
const ramp_threshold_angle = 10.0  # Minimum angle to consider a surface as ramped

# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Mouse look sensitivity
var mouse_sensitivity = Vector2(0.005, 0.005)

# View-bobbing variables
var bobbing_intensity = 0.1
var bobbing_speed = 10.0
var camera_original_position = Vector3.ZERO  # Original camera position for bobbing
var bobbing_time = 0.0  # Tracks bobbing animation time

# Swaying variables
var reverse_sway = true  # Controls the direction of the sway
var sway_intensity = 4.0  # Intensity of swaying effect
var max_sway_angle = 3.5  # Maximum angle for swaying

# Knockback effect variables
var knockback_intensity = 2.5  # Intensity of the knockback on landing
var knockback_speed = 0.025  # Speed of the knockback recovery

# Momentum variables
var speed_up_momentum = 0.3  # Factor for speeding up
var slow_down_momentum = 30.0  # Factor for slowing down

# Crouching variables
var is_crouching = false
var crouch_height = 0.5
var crouch_smoothing = 0.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_original_position = $Camera3D.transform.origin
	spawn_point = global_transform.origin  # Save the initial position

func _process(delta):
	slow_down_momentum = 30 * (current_speed / 4)  # Adjust slow down momentum based on current speed

	# Handle gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		on_ground_time = 0.0  # Reset ground time when not on the floor
		was_in_air = true  # Track that the player was in the air
	else:
		on_ground_time += delta  # Increase ground time while on the floor
		if on_ground_time >= time_to_reset_speed:
			bhop_speed = speed  # Reset speed back to normal

		# Trigger knockback effect if the player just landed
		if was_in_air:
			apply_knockback_effect()
			was_in_air = false

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		var surface_angle = get_floor_normal().angle_to(Vector3.UP) * 180 / PI
		
		if surface_angle > ramp_threshold_angle and current_speed > speed * 2:
			velocity.y = jump_velocity * ramp_jump_multiplier  # Apply ramp jump multiplier
		else:
			velocity.y = jump_velocity  # Normal jump on flat ground

		if allow_bhop and current_speed > 1: # Increase speed with cap, if you NOT jumping still
			bhop_speed = min(bhop_speed * bunny_hop_speed_increase, bunny_hop_speed_cap)

	# Handle movement inputs
	var input_dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("backward") - Input.get_action_strength("forward")
	)
	var direction = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Opposite inputs mid-air slow you down
	if not is_on_floor() and (direction.dot(Vector3(velocity.x, 0, velocity.z).normalized()) < -0.5 or Input.get_action_strength("backward")):
		velocity.x = move_toward(velocity.x, 0, slow_down_momentum * delta)  # Apply momentum for slowing down mid-air
		velocity.z = move_toward(velocity.z, 0, slow_down_momentum * delta) # Apply momentum for slowing down mid-air
		bhop_speed = speed

	# Handle momentum and movement
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * bhop_speed, speed_up_momentum)  # Apply momentum for speeding up
		velocity.z = lerp(velocity.z, direction.z * bhop_speed, speed_up_momentum)  # Apply momentum for speeding up
		bobbing_time += delta * bobbing_speed  # Increase bobbing time based on speed
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, slow_down_momentum * delta)  # Apply momentum for slowing down
			velocity.z = move_toward(velocity.z, 0, slow_down_momentum * delta)  # Apply momentum for slowing down
		else:
			# Maintain velocity while mid-air.
			velocity.x = lerp(velocity.x, velocity.x, 0.02)
			velocity.z = lerp(velocity.z, velocity.z, 0.02)
		# Slow bobbing when not moving, to avoid visual jarring
		bobbing_time += delta * (bobbing_speed * 0.5)

	move_and_slide()

	# Always set current speed to velocity
	current_speed = velocity.length()

	# Apply view-bobbing effect based on movement
	if velocity.length() > 0.1 and is_on_floor():
		var bobbing_amount = sin(bobbing_time) * bobbing_intensity
		$Camera3D.transform.origin.y = camera_original_position.y + bobbing_amount
	else:
		$Camera3D.transform.origin.y = lerp($Camera3D.transform.origin.y, camera_original_position.y, 5.0 * delta)

	# Apply player swaying based on horizontal movement
	var sway_factor = 0.0
	if input_dir.x != 0:
		if reverse_sway: # Reversing sway
			sway_factor = input_dir.x * max_sway_angle * -1 
		else:
			sway_factor = input_dir.x * max_sway_angle
	rotation_degrees.z = lerp(rotation_degrees.z, sway_factor, delta * sway_intensity)

	# Check if player falls below the specified Y position
	if global_transform.origin.y < fall_reset_y:
		# Reset player position to saved position
		global_transform.origin = spawn_point

func _input(event):
	if event is InputEventMouseMotion:
		# Handle mouse look
		var mouse_movement = Vector2(-event.relative.y, -event.relative.x) * mouse_sensitivity
		
		# Rotate the player horizontally
		rotate_y(mouse_movement.y)
		# Rotate the camera vertically
		$Camera3D.rotate_x(mouse_movement.x)
		
		# Clamp the camera's vertical rotation
		var clamped_x_rotation = clamp($Camera3D.rotation_degrees.x, -90, 90)
		$Camera3D.rotation_degrees.x = clamped_x_rotation

func apply_knockback_effect():
	# Apply a knockback effect on landing
	rotation_degrees.z += knockback_intensity
	
	# Await a brief moment before resetting the knockback
	await get_tree().create_timer(0.1).timeout
	
	# Smoothly reset the sway back to normal
	rotation_degrees.z = lerp(rotation_degrees.z, 0.0, float(knockback_speed) * get_physics_process_delta_time())
