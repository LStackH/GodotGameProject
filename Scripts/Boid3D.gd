extends Node3D

@export var speed: float = 5.0
@export var max_force: float = 0.3
@export var neighbor_radius: float = 10.0
@export var avoid_radius: float = 5.0
@export var central_point: Vector3 = Vector3.ZERO
@export var boundary_radius: float = 20.0

var velocity: Vector3
var acceleration: Vector3

func _ready():
	velocity = Vector3(randf() * 2 - 1, randf() * 2 - 1, randf() * 2 - 1).normalized() * speed
	acceleration = Vector3.ZERO

func _process(delta):
	var neighbors = get_neighbors()
	var separation = get_separation(neighbors)
	var alignment = get_alignment(neighbors)
	var cohesion = get_cohesion(neighbors)
	var avoidance = avoid_obstacles()
	var boundary = stay_within_boundary()
	
	acceleration = separation + alignment + cohesion + avoidance + boundary
	
	velocity += acceleration * delta
	velocity = velocity.normalized() * speed
	
	translate(velocity * delta)
	look_at(global_transform.origin + velocity, Vector3.UP)

func get_neighbors():
	var neighbors = []
	var all_boids = get_parent().get_children()
	for boid in all_boids:
		if boid is Node3D and boid != self and global_transform.origin.distance_to(boid.global_transform.origin) < neighbor_radius:
			neighbors.append(boid)
	return neighbors

func get_separation(neighbors):
	var steer = Vector3.ZERO
	for neighbor in neighbors:
		var diff = global_transform.origin - neighbor.global_transform.origin
		diff = diff.normalized() / global_transform.origin.distance_to(neighbor.global_transform.origin)
		steer += diff
	if steer.length() > 0:
		steer = steer.normalized() * speed - velocity
		steer = steer.normalized() * min(steer.length(), max_force)
	return steer

func get_alignment(neighbors):
	var avg_velocity = Vector3.ZERO
	for neighbor in neighbors:
		avg_velocity += neighbor.velocity
	if neighbors.size() > 0:
		avg_velocity /= neighbors.size()
		avg_velocity = avg_velocity.normalized() * speed
		var steer = avg_velocity - velocity
		steer = steer.normalized() * min(steer.length(), max_force)
		return steer
	return Vector3.ZERO

func get_cohesion(neighbors):
	var center_of_mass = Vector3.ZERO
	for neighbor in neighbors:
		center_of_mass += neighbor.global_transform.origin
	if neighbors.size() > 0:
		center_of_mass /= neighbors.size()
		var direction = center_of_mass - global_transform.origin
		direction = direction.normalized() * speed
		var steer = direction - velocity
		steer = steer.normalized() * min(steer.length(), max_force)
		return steer
	return Vector3.ZERO

func avoid_obstacles() -> Vector3:
	var avoid_vector = Vector3.ZERO
	var ray_length = avoid_radius

	var directions = [
		Vector3.FORWARD, 
		Vector3.BACK, 
		Vector3.LEFT, 
		Vector3.RIGHT, 
		Vector3.UP, 
		Vector3.DOWN
	]
	
	var space_state = get_world_3d().direct_space_state

	for direction in directions:
		var ray_origin = global_transform.origin
		var ray_end = ray_origin + direction * ray_length
		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_end
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		
		if result:
			var intersection_position = result.position
			var intersection_distance = ray_origin.distance_to(intersection_position)
			var avoid_force = ray_origin - intersection_position
			avoid_force = avoid_force.normalized() / intersection_distance
			avoid_vector += avoid_force
	
	if avoid_vector.length() > 0:
		avoid_vector = avoid_vector.normalized() * speed
		avoid_vector = avoid_vector.normalized() * min(avoid_vector.length(), max_force)
	
	return avoid_vector

func stay_within_boundary() -> Vector3:
	var boundary_vector = central_point - global_transform.origin
	var distance_to_center = boundary_vector.length()
	
	if distance_to_center > boundary_radius:
		boundary_vector = boundary_vector.normalized() * (distance_to_center - boundary_radius)
		return boundary_vector.normalized() * min(boundary_vector.length(), max_force)
	
	return Vector3.ZERO
