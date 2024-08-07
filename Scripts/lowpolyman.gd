extends CharacterBody3D

@onready var armature = $Armature
@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var base_camera = $SpringArmPivot/SpringArm3D/base_camera
@onready var anim_tree = $AnimationTree
@onready var info_label = $InfoLabel  # Reference to the new label node

@onready var fog_volume = get_parent().get_node("FogVolume")
@export var fog_material : ShaderMaterial

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LERP_VALUE = 0.25
const INITIAL_ROTATION_SPEED = 0.01
const MAX_ROTATION_SPEED = 0.03
const ACCELERATION_TIME = 1

var current_rotation_speed = INITIAL_ROTATION_SPEED
var rotation_acceleration = (MAX_ROTATION_SPEED - INITIAL_ROTATION_SPEED) / ACCELERATION_TIME
var last_input_time = -1.0

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
	
	# Initialize the camera position
	spring_arm.rotation_degrees = Vector3(-35, 45, 0)  # Adjusting the angle for isometric view
	spring_arm.spring_length = 5.0  # Starting spring length

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("reset_camera"):
		spring_arm_pivot.rotation_degrees.y = 0
		spring_arm.rotation_degrees = Vector3(-35, 45, 0)
		spring_arm.spring_length = 5.0
	
	# Camera rotation for mouse
	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * .003)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x - event.relative.y * .003, deg_to_rad(-60), deg_to_rad(-10))

	# Camera zooming for mouse
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
	
	# Update the info label with camera information
	info_label.text = "Camera Position: " + str(camera_position) + "\n" + \
					  "Camera Rotation: " + str(spring_arm.rotation_degrees) + "\n" + \
					  "Camera Height: " + str(spring_arm.spring_length)
	
	# Smooth camera rotation for Q and E keys with acceleration
	if Input.is_action_pressed("rotate_left"):
		if last_input_time < 0:  # Start timing
			last_input_time = Time.get_ticks_msec() / 1000.0
		else:
			var elapsed_time = (Time.get_ticks_msec() / 1000.0) - last_input_time
			current_rotation_speed = min(INITIAL_ROTATION_SPEED + rotation_acceleration * elapsed_time, MAX_ROTATION_SPEED)
			spring_arm_pivot.rotate_y(-current_rotation_speed)
	
	if Input.is_action_pressed("rotate_right"):
		if last_input_time < 0:  # Start timing
			last_input_time = Time.get_ticks_msec() / 1000.0
		else:
			var elapsed_time = (Time.get_ticks_msec() / 1000.0) - last_input_time
			current_rotation_speed = min(INITIAL_ROTATION_SPEED + rotation_acceleration * elapsed_time, MAX_ROTATION_SPEED)
			spring_arm_pivot.rotate_y(current_rotation_speed)
	
	if not (Input.is_action_pressed("rotate_left") or Input.is_action_pressed("rotate_right")):
		last_input_time = -1.0
		current_rotation_speed = INITIAL_ROTATION_SPEED


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = Vector3()
	if input_dir != Vector2.ZERO:
		var camera_transform = spring_arm.global_transform
		var forward = camera_transform.basis.z.normalized()
		var right = camera_transform.basis.x.normalized()

		direction = (input_dir.x * right + input_dir.y * forward).normalized()

	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_VALUE)
		velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_VALUE)
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VALUE)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VALUE)
		velocity.z = lerp(velocity.z, 0.0, LERP_VALUE)

	anim_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / SPEED)

	move_and_slide()
