extends CharacterBody3D

var player = null
var SPEED = 4.0

@export var player_path : NodePath

@onready var nav_agent = $NavigationAgent3D

func _ready():
	if player_path:
		player = get_node(player_path)
		if not player:
			print("Failed to find player node at path: ", player_path)
	else:
		print("Player path is not set.")

func _process(_delta):
	if player:
		velocity = Vector3.ZERO
		nav_agent.destination = player.global_transform.origin
		var next_nav_point = nav_agent.get_next_path_position()
		velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
		move_and_slide()
	else:
		print("Player node is not available.")
