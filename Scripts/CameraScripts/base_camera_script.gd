extends Camera3D

@export var target_node: Node3D  # Reference to the player node
@export var follow_speed: float = 5.0  # Speed at which the camera follows the player
@export var rotation_speed: float = 5.0  # Speed at which the camera rotates to face the target
@export var offset: Vector3 = Vector3(5, 2.5, 0)  # Camera offset from the player

var target_position: Vector3
var current_basis: Basis

func _ready() -> void:
	if target_node == null:
		print("Target node is not set. Please assign the player node.")
	else:
		# Initialize target position
		target_position = global_transform.origin
		current_basis = global_transform.basis

func _physics_process(delta: float) -> void:
	if target_node != null:
		# Calculate desired position
		var desired_position = target_node.global_transform.origin + offset
		
		# Smoothly interpolate towards desired position
		target_position = target_position.lerp(desired_position, follow_speed * delta)
		
		# Update camera position
		global_transform.origin = target_position
		
		# Smoothly interpolate rotation to look at the target
		var target_direction = (target_node.global_transform.origin - global_transform.origin).normalized()
		var target_basis = Basis().looking_at(target_direction, Vector3.UP)
		
		# Smoothly interpolate basis to avoid sudden jumps
		current_basis = current_basis.slerp(target_basis, rotation_speed * delta)
		global_transform.basis = current_basis
