extends CharacterBody3D

const SPEED = 1.2
const JUMP_VELOCITY = 2.5
const FRICTION = 10.0  # Adjust this value to control how quickly the character slows down

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D  # Assuming the Camera3D is a child node of the player

func _ready():
	# Initialization logic if needed
	pass

func _physics_process(delta):
	# Add gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Adjust the direction based on the camera's rotation.
	if direction != Vector3.ZERO:
		var camera_forward = camera.global_transform.basis.z
		var camera_right = camera.global_transform.basis.x

		# Calculate the movement direction relative to the camera.
		var move_dir = (camera_forward * direction.z + camera_right * direction.x).normalized()

		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		# Apply friction to velocity when no input is present.
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

	move_and_slide()
