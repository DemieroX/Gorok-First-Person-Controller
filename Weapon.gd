extends Node3D

# Variables for weapon bobbing
var bobbing_intensity = 0.01
var bobbing_speed = 15.0
var idle_bobbing_intensity = 0.014
var idle_bobbing_speed = 3
var weapon_original_position = Vector3.ZERO
var bobbing_time = 0.0

# Reference to the CharacterBody3D node
var character: CharacterBody3D

# Variables for backward movement
var max_backward_offset = 0.15  # Maximum backward offset
var speed_to_offset_factor = 0.01  # Factor to scale the backward offset based on speed
var backward_offset_smooth = 0.5  # Smoothed backward offset
var smoothing_factor = 10.0  # Higher value means faster smoothing

# Variables for weapon-mouse sway
var sway_intensity = 0.00005  # How much the weapon sways
var sway_smoothing = 6.0  # Smoothing factor for the sway effect
var sway_offset = Vector3.ZERO  # Current sway offset
var max_sway = Vector2(0.13, 0.3)  # Maximum sway limits for x and y axes

func _ready():
	weapon_original_position = transform.origin
	# Initialize reference to the CharacterBody3D node
	character = get_parent().get_parent()

func _process(delta):
	# Weapon bobbing logic
	if character and character.velocity.length() > 0.1 and character.is_on_floor():
		bobbing_time += delta * bobbing_speed
		var bobbing_amount = sin(bobbing_time) * bobbing_intensity
		transform.origin.y = weapon_original_position.y + bobbing_amount
	else:
		# Idle bobbing logic
		bobbing_time += delta * idle_bobbing_speed
		var bobbing_amount = sin(bobbing_time) * idle_bobbing_intensity
		transform.origin.y = weapon_original_position.y + bobbing_amount

	# Calculate backward offset based on player speed
	if character:
		var speed = character.velocity.length()
		var target_backward_offset = min(speed * speed_to_offset_factor, max_backward_offset)
		# Smoothly adjust the backward offset
		backward_offset_smooth = lerp(backward_offset_smooth, target_backward_offset, smoothing_factor * delta)
		transform.origin.z = weapon_original_position.z + backward_offset_smooth

	# Calculate weapon sway based on mouse movement
	var mouse_delta = Input.get_last_mouse_velocity()
	
	# Invert Y-axis and apply lerp for smoother sway
	sway_offset.x = lerp(sway_offset.x, -mouse_delta.x * sway_intensity, sway_smoothing * delta)
	sway_offset.y = lerp(sway_offset.y, mouse_delta.y * sway_intensity, sway_smoothing * delta)

	# Clamp the sway values
	sway_offset.x = clamp(sway_offset.x, -max_sway.x, max_sway.x)
	sway_offset.y = clamp(sway_offset.y, -max_sway.y, max_sway.y)

	# Apply the sway to the weapon's position
	transform.origin.x = weapon_original_position.x + sway_offset.x
	transform.origin.y += sway_offset.y
