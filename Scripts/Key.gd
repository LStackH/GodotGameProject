extends Area3D  # Use Area3D for simplicity

@export var pickup_distance: float = 3.0  # Distance within which the player can pick up the key
@export var bounce_amplitude: float = 1.0  # Amplitude of the bounce
@export var bounce_speed: float = 1.0      # Speed of the bounce

@onready var player = get_parent().get_node("Player")  # Adjust the path to your player node

var initial_position: Vector3  # Initial position of the key
var elapsed_time: float = 0.0  # Elapsed time for sine wave calculation

func _ready():
	initial_position = global_transform.origin  # Store the initial position of the key

func _process(delta):
	elapsed_time += delta * bounce_speed  # Increment elapsed time by the delta time multiplied by the bounce speed
	bounce_key()  # Call the function to bounce the key

	if is_player_nearby():
		check_mouse_pickup()

func is_player_nearby() -> bool:
	return global_transform.origin.distance_to(player.global_transform.origin) < pickup_distance

func check_mouse_pickup():
	if Input.is_action_just_pressed("click"):
		if is_player_nearby():
			pickup_key()

func pickup_key():
	queue_free()  # For now, just remove the key from the scene. Later, you can add inventory logic.
	# Add logic to update player's inventory or state

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var space_state = get_world_3d().direct_space_state
			var from = get_viewport().get_camera_3d().project_ray_origin(get_viewport().get_mouse_position())
			var to = from + get_viewport().get_camera_3d().project_ray_normal(get_viewport().get_mouse_position()) * 1000

			# Use a PhysicsRayQueryParameters3D for the raycast
			var query = PhysicsRayQueryParameters3D.new()
			query.from = from
			query.to = to
			query.collision_mask = 1

			var result = space_state.intersect_ray(query)

			if result and result.collider == self:
				if is_player_nearby():
					pickup_key()


func _on_body_entered(body):
	if body.name == "Player":  # Adjust the condition as needed
		pickup_key()
		print("picked up key")

func bounce_key():
	# Calculate the new vertical position using a sine wave
	var new_y = initial_position.y + sin(elapsed_time) * bounce_amplitude
	global_transform.origin.y = new_y  # Update the key's position
