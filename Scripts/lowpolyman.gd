extends CharacterBody3D

@onready var armature = $Armature
@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var anim_tree = $AnimationTree

@onready var fog_volume = get_parent().get_node("FogVolume")
@export var fog_material : ShaderMaterial

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LERP_VALUE = 0.25
var zoom_min = 2.0
var zoom_max = 10.0
var zoom_speed = 0.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	fog_material = fog_volume.material
	fog_material.set_shader_parameter("fog_start", 1.0)
	fog_material.set_shader_parameter("fog_end", 20.0)
	fog_material.set_shader_parameter("fog_density", 0.05)
	fog_material.set_shader_parameter("clear_radius", 5.0)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * .003)
		spring_arm.rotate_x(-event.relative.y * .003)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/3, PI/3)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = max(zoom_min, spring_arm.spring_length - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = min(zoom_max, spring_arm.spring_length + zoom_speed)

func _process(delta):
	var camera_position = spring_arm.global_transform.origin
	var player_position = global_transform.origin
	fog_material.set_shader_parameter("camera_position", camera_position)
	fog_material.set_shader_parameter("player_position", player_position)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	if direction:
		velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_VALUE)
		velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_VALUE)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VALUE)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VALUE)
		velocity.z = lerp(velocity.z, 0.0, LERP_VALUE)

	anim_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED )

	move_and_slide()
