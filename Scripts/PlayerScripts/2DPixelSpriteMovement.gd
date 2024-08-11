extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_force: float = 10.0
@export var gravity: float = -20.0

# Node references
@onready var sprite: Sprite3D = $Sprite3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Input handling
func get_input_direction() -> Vector3:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("left"):
		direction.z += 1  # Move West (negative Z)
	if Input.is_action_pressed("right"):
		direction.z -= 1  # Move East (positive Z)
	if Input.is_action_pressed("forward"):
		direction.x -= 1  # Move Up (positive X)
	if Input.is_action_pressed("backwards"):
		direction.x += 1  # Move Down (negative X)

	return direction

# Main physics function
func _physics_process(delta: float) -> void:
	var direction = get_input_direction()
	var velocity = self.velocity

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Play walk animation
		if not anim_player.is_playing() or anim_player.current_animation != "walk":
			anim_player.play("walk")

		# Flip sprite based on direction
		if direction.z > 0:
			sprite.flip_h = true  # Moving East
		elif direction.z < 0:
			sprite.flip_h = false  # Moving West
	else:
		# Stop movement and animation if no input
		velocity.x = 0
		velocity.z = 0
		if anim_player.is_playing():
			anim_player.stop()

	# Apply gravity
	velocity.y += gravity * delta

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	self.velocity = velocity

	# Move the character
	move_and_slide()
