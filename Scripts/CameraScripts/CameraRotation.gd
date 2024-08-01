extends Camera3D

@export var mouse_sensitivity : float = 0.001  # Sensitivity of mouse movement
@export var rotation_speed : float = 10.0      # Speed of smoothing the rotation
@export var zoom_sensitivity : float = 0.1     # Sensitivity of zooming with mouse scroll
@export var min_radius : float = 0.5            # Minimum distance from the player
@export var max_radius : float = 3.0           # Maximum distance from the player
@export var radius : float = 1.5                # Initial distance from the player
@export var min_height : float = 0.5            # Minimum height of the camera
@export var max_height : float = 5.0            # Maximum height of the camera
@export var height : float = 1.2                # Initial height of the camera relative to the player
@export var min_vertical_rotation : float = deg_to_rad(-70)  # Min vertical rotation in radians
@export var max_vertical_rotation : float = deg_to_rad(70)   # Max vertical rotation in radians
@export var rotation_step : float = deg_to_rad(1)  # Rotation step for Q and E keys

@onready var player = get_parent()

var target_rotation : Vector3 = Vector3.ZERO  # Target rotation angles in radians
var smooth_rotation : Vector3 = Vector3.ZERO  # Current rotation angles in radians
var initial_position : Vector3  # Initial camera position
var initial_rotation : Vector3  # Initial camera rotation
var initial_radius : float      # Initial camera distance from the player
var initial_height : float      # Initial height of the camera relative to the player
var is_right_click_held : bool = false         # To track if right mouse button is held down

func _ready():
	# Lock the mouse to the window center
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Store initial camera position, rotation, radius, and height
	initial_position = global_transform.origin
	initial_rotation = smooth_rotation
	initial_radius = radius
	initial_height = height
	
	set_camera_position()

func _process(delta):
	# Smoothly interpolate to the target rotation
	smooth_rotation.x = lerp_angle(smooth_rotation.x, target_rotation.x, delta * rotation_speed)
	smooth_rotation.y = lerp_angle(smooth_rotation.y, target_rotation.y, delta * rotation_speed)
	
	# Apply the rotation to the camera
	global_transform.basis = Basis().rotated(Vector3.UP, smooth_rotation.y).rotated(Vector3.RIGHT, smooth_rotation.x)
	
	# Update the camera position based on the new rotation
	set_camera_position()

	# Check for reset input
	if Input.is_action_just_pressed("reset_camera"):
		reset_camera()

	# Check for rotation input
	if Input.is_action_pressed("rotate_left"):
		target_rotation.y -= rotation_step
	if Input.is_action_pressed("rotate_right"):
		target_rotation.y += rotation_step

func _unhandled_input(event):
	if event is InputEventMouseMotion and is_right_click_held:
		# Update target rotation based on mouse movement
		target_rotation.x -= event.relative.y * mouse_sensitivity
		target_rotation.y -= -(event.relative.x) * mouse_sensitivity
		
		# Limit vertical rotation to prevent flipping and clipping
		target_rotation.x = clamp(target_rotation.x, min_vertical_rotation, max_vertical_rotation)

		# Normalize horizontal rotation to prevent snapping
		target_rotation.y = wrap_angle(target_rotation.y)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_right_click_held = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				is_right_click_held = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom in
		update_camera_zoom(-zoom_sensitivity)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom out
		update_camera_zoom(zoom_sensitivity)

func update_camera_zoom(delta_zoom: float):
	# Adjust radius and height
	var new_radius = clamp(radius + delta_zoom, min_radius, max_radius)
	var zoom_factor = new_radius / radius
	
	# Maintain consistent view angle by adjusting height proportionally
	height = clamp(height * zoom_factor, min_height, max_height)
	
	# Update radius and set new camera position
	radius = new_radius
	set_camera_position()

func wrap_angle(angle: float) -> float:
	# Normalize angle to be within -PI to PI
	return atan2(sin(angle), cos(angle))

func set_camera_position():
	# Compute the camera's position based on the target rotation and radius
	var angle_y = smooth_rotation.y
	var angle_x = smooth_rotation.x
	var cos_x = cos(angle_x)
	var sin_x = sin(angle_x)
	var cos_y = cos(angle_y)
	var sin_y = sin(angle_y)

	var camera_x = player.global_transform.origin.x + radius * cos_y * cos_x
	var camera_z = player.global_transform.origin.z + radius * sin_y * cos_x
	var camera_y = player.global_transform.origin.y + height + radius * sin_x
	
	global_transform.origin = Vector3(camera_x, camera_y, camera_z)
	look_at(player.global_transform.origin, Vector3.UP)

func reset_camera():
	# Reset camera position, rotation, radius, and height to the initial values
	global_transform.origin = initial_position
	smooth_rotation = initial_rotation
	target_rotation = initial_rotation
	radius = initial_radius
	height = initial_height
	set_camera_position()
