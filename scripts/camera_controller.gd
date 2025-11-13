extends Camera3D

signal camera_moved(position: Vector3, rotation: Vector3)

@export var move_speed: float = 20.0
@export var vertical_speed: float = 15.0
@export var rotate_keys_speed: float = 60.0
@export var orbit_sensitivity: float = 0.005
@export var zoom_speed: float = 8.0
@export var min_distance: float = 5.0
@export var max_distance: float = 100.0

var is_orbiting: bool = false
var zoom_target: float
var orbit_center: Vector3 = Vector3.ZERO

var _last_position: Vector3
var _last_rotation: Vector3

func _ready() -> void:
	current = true
	if position == Vector3.ZERO:
		position = Vector3(0, 10, -20)
	zoom_target = clamp(-position.z, min_distance, max_distance)
	_last_position = global_position
	_last_rotation = rotation
	add_to_group("main_camera")

# -------------------------------------------------------------------------
#  Mise à jour continue
# -------------------------------------------------------------------------
func _process(delta: float) -> void:
	var pivot: Node3D = get_parent() as Node3D
	var input_dir := Vector3.ZERO

	# --- Déplacement ZQSD ---
	if Input.is_action_pressed("move_forward"):  input_dir.z -= 1
	if Input.is_action_pressed("move_backward"): input_dir.z += 1
	if Input.is_action_pressed("move_left"):     input_dir.x -= 1
	if Input.is_action_pressed("move_right"):    input_dir.x += 1

	if input_dir != Vector3.ZERO:
		pivot.translate(input_dir.normalized() * move_speed * delta)

	# --- Monter / descendre ---
	if Input.is_action_pressed("move_up"):   pivot.position.y += vertical_speed * delta
	if Input.is_action_pressed("move_down"): pivot.position.y -= vertical_speed * delta

	# --- Rotation avec touches (Y) ---
	if Input.is_action_pressed("move_rotate_left"):
		pivot.rotate_y(deg_to_rad(-rotate_keys_speed * delta))
	elif Input.is_action_pressed("move_rotate_right"):
		pivot.rotate_y(deg_to_rad(rotate_keys_speed * delta))

	# --- Orbit caméra avec clic molette (rotation instantanée) ---
	if is_orbiting:
		var v: Vector2 = Input.get_last_mouse_velocity()
		var delta_yaw := -v.x * orbit_sensitivity * delta
		_rotate_around_point(orbit_center, delta_yaw)

	# --- Zoom ---
	#var current_distance: float = -position.z
	#var target_distance: float = clamp(zoom_target, min_distance, max_distance)
	#var new_distance: float = lerp(current_distance, target_distance, 6.0 * delta)
	#position.z = -new_distance

	# --- Détection de mouvement pour UI ---
	if global_position != _last_position or rotation != _last_rotation:
		_last_position = global_position
		_last_rotation = rotation
		emit_signal("camera_moved", global_position, rotation)

# -------------------------------------------------------------------------
#  Entrées utilisateur (molette, clic molette)
# -------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# 🚫 Ignore tout input si la souris survole un élément UI
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null:
			return

		# --- Orbit ---
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_orbiting = true
				orbit_center = _get_mouse_hit_point()
			else:
				is_orbiting = false

		# --- Zoom ---
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target += zoom_speed

# -------------------------------------------------------------------------
#  Calcul du point d'orbite (raycast ou plan de secours)
# -------------------------------------------------------------------------
func _get_mouse_hit_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mouse)
	var dir := project_ray_normal(mouse)
	var space := get_world_3d().direct_space_state

	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 5000.0)
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.collision_mask = 0xFFFFFFFF

	var hit := space.intersect_ray(params)

	if hit.is_empty():
		var plane := Plane(Vector3.UP, 0.0)
		var pos: Variant = plane.intersects_ray(origin, dir)
		if pos != null:
			return pos + Vector3(0, 2.0, 0)
		else:
			return Vector3(0, 2.0, 0)
	else:
		return hit.position + Vector3(0, 2.0, 0)

# -------------------------------------------------------------------------
#  Rotation orbitale autour d'un point
# -------------------------------------------------------------------------
func _rotate_around_point(center: Vector3, delta_yaw: float) -> void:
	var pivot: Node3D = get_parent() as Node3D
	var pivot_to_center := center - pivot.global_position
	var rot := Basis(Vector3.UP, delta_yaw)
	pivot_to_center = rot * pivot_to_center
	pivot.global_position = center - pivot_to_center
	pivot.rotate_y(delta_yaw)
