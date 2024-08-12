extends CharacterBody3D

@export var speed: float = 5.0
@export var run_speed: float = 7.5  # Speed when running
@export var jump_force: float = 7.5
@export var gravity: float = -20.0
@export var attack_deceleration: float = 10.0  # Rate at which speed reduces during attack
@export var attack_range: float = 3.0
@export var attack_damage: int = 1
@export var health_max: int = 10
@export var health_min: int = 0

# Node references
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Reference to the AnimatedSprite3D node
@onready var health_current: int = health_max

var moving: bool = false
var is_jumping: bool = false
var is_attacking: bool = false

# Input handling
func get_input_direction() -> Vector3:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("left"):
		direction.z += 1  # Move West (positive Z)
	if Input.is_action_pressed("right"):
		direction.z -= 1  # Move East (negative Z)
	if Input.is_action_pressed("forward"):
		direction.x -= 1  # Move Up (negative X)
	if Input.is_action_pressed("backwards"):
		direction.x += 1  # Move Down (positive X)

	return direction

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("primary_action") and not is_attacking:
		start_attack()

func _physics_process(delta: float) -> void:
	var direction = get_input_direction()
	velocity = self.velocity
	
	if is_attacking:
		# Gradually reduce horizontal speed during attack
		velocity.x = move_toward(velocity.x, 0, attack_deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, attack_deceleration * delta)
		velocity.y += gravity * delta
		
		# Ensure vertical movement is influenced by gravity
		if not sprite.is_playing():
			is_attacking = false
			if is_on_floor() and not moving:
				sprite.play("idle")
		self.velocity = velocity
		move_and_slide()
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		if not is_jumping:
			is_jumping = true
			sprite.play("jump")
			velocity.y = jump_force
	
	# Handle movement
	if direction != Vector3.ZERO and not is_attacking:
		moving = true
		direction = direction.normalized()
		var current_speed = run_speed if Input.is_action_pressed("run") else speed
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		sprite.flip_h = direction.z > 0  # Flip sprite based on direction
		
		# Play movement animations only if not jumping or attacking
		if not is_jumping:
			if current_speed == run_speed and sprite.animation != "run":
				sprite.play("run")
			elif current_speed == speed and sprite.animation != "walk":
				sprite.play("walk")
	else:
		velocity.x = 0
		velocity.z = 0
		moving = false
	
	# Update the character's velocity and move
	self.velocity = velocity
	move_and_slide()
	
	# Handle idle state
	if is_on_floor() and not moving and not is_jumping and not is_attacking:
		if sprite.animation != "idle":
			sprite.play("idle")
	
	# Reset jump state when on the floor
	if is_on_floor():
		is_jumping = false

func start_attack():
	is_attacking = true
	sprite.stop()  # Stop any current animation
	sprite.play("attack")
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc is CharacterBody3D:
			if global_transform.origin.distance_to(npc.global_transform.origin) <= attack_range:
				npc.take_damage(attack_damage)
	await sprite.animation_finished
	is_attacking = false
	
func take_damage(damage: int) -> void:
	health_current -= damage
	if health_current <= 0:
		die()
	print("Player health", health_current)
		
func die() -> void:
	#TODO logic for dying
	print("Player has died")
