extends Camera3D

signal camera_moved(position: Vector3, rotation: Vector3)

@export var move_speed: float = 20.0
@export var vertical_speed: float = 15.0
@export var rotate_keys_speed: float = 60.0
@export var orbit_sensitivity: float = 0.25
@export var zoom_speed: float = 8.0
@export var min_distance: float = 5.0
@export var max_distance: float = 100.0

var is_orbiting: bool = false
var zoom_target: float

# Mémorisation de la position précédente pour détecter les mouvements
var _last_position: Vector3
var _last_rotation: Vector3

func _ready() -> void:
	if position == Vector3.ZERO:
		position = Vector3(0, 10, -20)
	zoom_target = clamp(-position.z, min_distance, max_distance)
	_last_position = global_position
	_last_rotation = rotation
	add_to_group("main_camera")

func _process(delta: float) -> void:
	var pivot: Node3D = get_parent() as Node3D
	var input_dir: Vector3 = Vector3.ZERO

	# --- Déplacement ---
	if Input.is_action_pressed("move_forward"):  input_dir.z -= 1
	if Input.is_action_pressed("move_backward"): input_dir.z += 1
	if Input.is_action_pressed("move_left"):     input_dir.x -= 1
	if Input.is_action_pressed("move_right"):    input_dir.x += 1
	if input_dir != Vector3.ZERO:
		pivot.translate(input_dir.normalized() * move_speed * delta)

	# --- Monter / descendre ---
	if Input.is_action_pressed("move_up"):   pivot.position.y += vertical_speed * delta
	if Input.is_action_pressed("move_down"): pivot.position.y -= vertical_speed * delta

	# --- Rotation avec touches ---
	if Input.is_action_pressed("move_rotate_left"):
		pivot.rotate_y(deg_to_rad(-rotate_keys_speed * delta))
	elif Input.is_action_pressed("move_rotate_right"):
		pivot.rotate_y(deg_to_rad(rotate_keys_speed * delta))

	# --- Orbit (rotation à la souris) ---
	if is_orbiting:
		var v: Vector2 = Input.get_last_mouse_velocity() * delta
		pivot.rotate_y(-v.x * orbit_sensitivity)
		pivot.rotate_x(-v.y * orbit_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# --- Zoom ---
	var current_distance: float = -position.z
	var target_distance: float = clamp(zoom_target, min_distance, max_distance)
	var new_distance: float = lerp(current_distance, target_distance, 6.0 * delta)
	position.z = -new_distance

	# --- Détection de mouvement pour UI ---
	if global_position != _last_position or rotation != _last_rotation:
		_last_position = global_position
		_last_rotation = rotation
		emit_signal("camera_moved", global_position, rotation)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				is_orbiting = event.pressed
				if event.pressed:
					_set_pivot_to_mouse_hit()

func _set_pivot_to_mouse_hit() -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = project_ray_origin(mouse)
	var dir: Vector3 = project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 5000.0)
	params.collide_with_bodies = true

	var hit: Dictionary = space.intersect_ray(params)
	var pivot: Node3D = get_parent() as Node3D

	if hit.is_empty():
		var plane := Plane(Vector3.UP, 0.0)
		var pos: Variant = plane.intersects_ray(origin, dir)
		if pos != null:
			pivot.global_position = pos
	else:
		pivot.global_position = hit.position
