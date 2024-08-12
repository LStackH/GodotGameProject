extends CharacterBody3D

@export var speed: float = 3.0  # NPC movement speed
@export var attack_range: float = 2.0  # Range within which the NPC can attack the player
@export var gravity: float = -20.0
@export var attack_damage: int = 1  # Damage dealt by the NPC's attack
@export var attack_cooldown: float = 1.0  # Time between attacks
@export var health_max: int = 5  # NPC health
@export var health_min: int = 0


# Node references
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D  # Reference to the AnimatedSprite3D node
@onready var player: Node = get_parent().get_parent().get_node("Player2D")  # Reference to the player character
@onready var health_current: int = health_max


var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	add_to_group("npc") # npc group so the player can damage
	
	if not player:
		print("Player not found in the scene tree!")
		return

func _physics_process(delta: float) -> void:
	if is_dead or not player:
		return
	
	
	var player_direction = player.global_transform.origin - global_transform.origin
	velocity = self.velocity
	
	if player_direction.length() <= attack_range:
		if not is_attacking:
			print("attacking")
			start_attack(player_direction)
	elif player_direction.length() <= 10:
		#print("Player in sight")
		player_direction = player_direction.normalized()
		velocity.x = player_direction.x * speed
		velocity.z = player_direction.z * speed
		sprite.flip_h = player_direction.z > 0  # Flip sprite based on direction
		if not is_attacking:
			sprite.play("walk")
	else:
		velocity.x = 0
		velocity.z = 0
		if not is_attacking:
			sprite.play("idle")
		#print("Player not in sight, idling")
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	self.velocity = velocity
	move_and_slide()
	
	var is_moving = velocity.x != 0 or velocity.z != 0

func start_attack(player_direction) -> void:
	is_attacking = true
	sprite.stop()
	sprite.play("attack")
	#timer.start()
	
func _on_animated_sprite_3d_frame_changed():
	# This function is called every time the animation frame changes
	if sprite.animation == "attack" and sprite.frame == 3:
		print("Attack frame reached")
		var player_direction = player.global_transform.origin - global_transform.origin
		if player_direction.length() <= attack_range:
			player.take_damage(attack_damage)

func _on_animated_sprite_3d_animation_finished():
		# This function is called when the attack animation finishes
	is_attacking = false
	if is_on_floor() and self.velocity.x == 0 and self.velocity.z == 0:
		sprite.play("idle")
	else:
		sprite.play("walk")

func take_damage(damage: int) -> void:
	if is_dead:
		return

	health_current -= damage

	if health_current > 0:
		# Play hurt animation
		sprite.stop()
		sprite.play("hurt")

		await sprite.animation_finished

		# Return to idle or walk after hurt animation
		var is_moving = self.velocity.x != 0 or self.velocity.z != 0
		sprite.play("idle" if not is_moving else "walk")
	else:
		# Play death animation and handle NPC death
		die()

func die() -> void:
	is_dead = true
	sprite.stop()
	sprite.play("death")

	# After the death animation, remove the NPC from the scene
	await sprite.animation_finished
	queue_free()  # Remove the NPC from the scene





