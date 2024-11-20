extends ProgressBar

var target_value = 0.0  # The value we want to smoothly transition to
var smoothing_speed = 5.0  # Speed of the smoothing of the bar

func _ready():
	# Initialize target_value to the current value of the progress bar
	target_value = value

func _process(delta):
	# Update the target_value based on the parent’s current_speed
	target_value = (get_parent().current_speed / get_parent().bunny_hop_speed_cap) * 100
	
	# Smoothly interpolate the current value towards the target_value
	value = lerp(value, target_value, smoothing_speed * delta)
