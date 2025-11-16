extends Control

signal layer_changed(layer_name: String)

@onready var layer_tab_bar: TabBar = $VBoxContainer/FoldableTiles/VBoxContainer/LayerTabBar

var camera: Camera3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_find_main_camera()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if camera == null:
		_find_main_camera()
		print(camera)
		if camera == null:
			print("⚠️ No camera")
			return
	_on_camera_moved(camera.get_parent().position)
	_on_grid_cell_changed()

#  Recherche de la caméra principale
func _find_main_camera() -> void:
	var cam_node := get_tree().get_first_node_in_group("main_camera")
	if cam_node and cam_node is Camera3D:
		camera = cam_node
		if not camera.is_connected("camera_moved", Callable(self, "_on_camera_moved")):
			camera.connect("camera_moved", Callable(self, "_on_camera_moved"), CONNECT_ONE_SHOT)

func update_layer(layer_name: String) -> void:
	$VBoxContainer/FoldableTiles/VBoxContainer/HBoxContainer/TileLayerValue.text = layer_name

func _on_camera_moved(_position: Vector3) -> void:
	$VBoxContainer/FoldableCamera/VBoxContainer/HBoxContainerX/XCameraValue.text = "️%.1f" % _position.x
	$VBoxContainer/FoldableCamera/VBoxContainer/HBoxContainerZ/ZCameraValue.text = "️%.1f" % _position.z
	$VBoxContainer/FoldableCamera/VBoxContainer/HBoxContainerY/YCameraValue.text = "️%.1f" % _position.y

func _on_map_loaded(map_data: Dictionary) -> void:
	print(map_data)
	$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer/MapNameValue.text = map_data['name']
	$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer2/MapRadiusValue.text = str(int(map_data['radius']))

func _on_grid_cell_changed() -> void:
	# --- Calcul de la tuile sous la souris ---
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var dir: Vector3 = camera.project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state # correction ici
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 5000.0)
	params.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(params)

	if not hit.is_empty():
		var hit_pos: Vector3 = hit.position
		var axial: Vector2 = HexMath.world_to_axial(hit_pos)
		$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer3/HBoxContainer/MapGridQValue.text = "%d" % int(axial.x)
		$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer3/HBoxContainer/MapGridRValue.text = "%d" % int(axial.y)
	else:
		$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer3/HBoxContainer/MapGridQValue.text = ""
		$VBoxContainer/FoldableMap/VBoxContainer/HBoxContainer3/HBoxContainer/MapGridRValue.text = ""

func _on_layer_tab_bar_tab_changed(tab: int) -> void:
	match tab:
		0:
			emit_signal("layer_changed", "terrain")
		1:
			emit_signal("layer_changed", "building")
		2:
			emit_signal("layer_changed", "resource")
