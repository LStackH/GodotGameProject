extends Node3D

# References to important nodes
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/base_camera
@onready var player: CharacterBody3D = $".."

# Camera offset parameters
@export var camera_offset: Vector3 = Vector3(0, 5, 0)  # Adjust Y value for central positioning
@export var follow_speed: float = 5.0  # Speed at which the camera follows the player

# Zoom parameters
@export var zoom_speed: float = 5.0  # Speed of zooming
@export var min_zoom: float = 2.0  # Minimum zoom distance
@export var max_zoom: float = 10.0  # Maximum zoom distance

func _process(delta: float) -> void:
	# Position the camera arm so it follows the player, restricted to the Z axis (East-West)
	var target_position = player.global_transform.origin + camera_offset
	target_position.y = spring_arm.global_transform.origin.y  # Lock the Y position (height)
	target_position.x = spring_arm.global_transform.origin.x  # Lock the X position (depth)
	
	# Smoothly move the spring arm towards the target position
	spring_arm.global_transform.origin = spring_arm.global_transform.origin.lerp(target_position, follow_speed * delta)
	
	# Handle zooming with mouse scroll
	handle_zoom(delta)

func handle_zoom(delta: float) -> void:
	var scroll_input = Input.get_action_strength("scroll_up") - Input.get_action_strength("scroll_down")
	
	# Adjust spring arm length based on scroll input
	if scroll_input != 0:
		var new_length = spring_arm.length - scroll_input * zoom_speed * delta
		spring_arm.length = clamp(new_length, min_zoom, max_zoom)
