extends HBoxContainer

@onready var label_camera: Label = $LabelCamera
@onready var label_tile: Label = $LabelTile
@onready var label_height: Label = $LabelHeight
@onready var label_layer: Label = $LabelLayer
@onready var label_fps: Label = $LabelFPS
@onready var label_camera_icon: Label = $LabelCameraIcon
@onready var label_tile_icon: Label = $LabelTileIcon
@onready var label_height_icon: Label = $LabelHeightIcon
@onready var label_layer_icon: Label = $LabelLayerIcon
@onready var label_fps_icon: Label = $LabelFPSIcon

var camera: Camera3D = null
var math: Node = null
var _time_accum: float = 0.0
var _frame_count: int = 0
const FPS_REFRESH_RATE := 0.5

func _ready() -> void:
	_find_main_camera()
	math = preload("res://scripts/hex_math.gd").new()
	set_process(true)
	label_tile_icon.text = "\uF312"
	label_camera_icon.text = "\uF3C5"
	label_height_icon.text = "\uF6FC"
	label_fps_icon.text = "\uF611"

func _process(delta: float) -> void:
	# --- FPS ---
	_time_accum += delta
	_frame_count += 1
	if _time_accum >= FPS_REFRESH_RATE:
		label_fps.text = "%d" % int(_frame_count / _time_accum)
		_time_accum = 0.0
		_frame_count = 0

	if camera == null:
		_find_main_camera()
		if camera == null:
			label_camera.text = "No camera"
			return

	# --- Infos caméra ---
	label_camera.text = "%.1f, %.1f" % [camera.get_parent().position.x, camera.get_parent().position.z]
	label_height.text = "️%.1f" % camera.get_parent().position.y

	# --- Calcul de la tuile sous la souris ---
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var dir: Vector3 = camera.project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state  #  correction ici
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 5000.0)
	params.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(params)

	if not hit.is_empty():
		var hit_pos: Vector3 = hit.position
		var axial: Vector2 = math.world_to_axial(hit_pos)
		label_tile.text = "q=%d, r=%d" % [int(axial.x), int(axial.y)]
	else:
		label_tile.text = "—"

#  Recherche de la caméra principale
func _find_main_camera() -> void:
	var cam_node := get_tree().get_first_node_in_group("main_camera")
	if cam_node and cam_node is Camera3D:
		camera = cam_node
		if not camera.is_connected("camera_moved", Callable(self, "_on_camera_moved")):
			camera.connect("camera_moved", Callable(self, "_on_camera_moved"), CONNECT_ONE_SHOT)

#  Réception du signal de déplacement
func _on_camera_moved(_position: Vector3, _rotation: Vector3) -> void:
	label_camera.text = "%.1f, %.1f" % [_position.x, _position.z]
	label_height.text = "️%.1f" % _position.y
