extends CharacterBody3D

@export var speed: float = 5.0
@export var detection_radius: float = 10.0
@export var player_name: String = "Player"

@onready var player_node: CharacterBody3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	player_node = get_parent().get_node(player_name)

func _physics_process(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0  # Reset the y velocity when on the floor

	# Calculate distance to the player
	var distance_to_player = global_transform.origin.distance_to(player_node.global_transform.origin)

	# If the player is within the detection radius, move towards the player
	if distance_to_player < detection_radius:
		var direction = (player_node.global_transform.origin - global_transform.origin).normalized()
		direction.y = 0  # Ensure the mob moves only on the XZ plane
		velocity.x = lerp(velocity.x, direction.x * speed, 0.25)
		velocity.z = lerp(velocity.z, direction.z * speed, 0.25)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.25)
		velocity.z = lerp(velocity.z, 0.0, 0.25)

	# Move the mob using CharacterBody3D's move_and_slide function
	move_and_slide()
