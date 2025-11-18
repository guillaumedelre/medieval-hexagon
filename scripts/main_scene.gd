extends Control

@onready var chk_fullscreen: CheckBox = $WindowVideo/VBoxContainer/CheckFullscreen
@onready var chk_vsync: CheckBox = $WindowVideo/VBoxContainer/CheckVSync
@onready var opt_resolution: OptionButton = $WindowVideo/VBoxContainer/OptionResolution

const CONFIG_PATH := "user://settings.cfg"

var available_resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

func _ready() -> void:
	$WindowNewMap.hide()
	$WindowOpenMap.hide()
	$WindowVideo.hide()
	_load_resolutions()
	_load_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)

	if err != OK:
		print("No existing settings. Applying defaults.")
		return

	if cfg.has_section_key("video", "fullscreen"):
		chk_fullscreen.button_pressed = cfg.get_value("video", "fullscreen")

	if cfg.has_section_key("video", "vsync"):
		chk_vsync.button_pressed = cfg.get_value("video", "vsync")

	if cfg.has_section_key("video", "resolution"):
		var idx = int(cfg.get_value("video", "resolution"))
		if idx >= 0 and idx < available_resolutions.size():
			opt_resolution.selected = idx


func _save_settings() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("video", "fullscreen", chk_fullscreen.button_pressed)
	cfg.set_value("video", "vsync", chk_vsync.button_pressed)
	cfg.set_value("video", "resolution", opt_resolution.selected)

	cfg.save(CONFIG_PATH)


func _load_resolutions() -> void:
	opt_resolution.clear()
	# Resolution actuelle
	var current = DisplayServer.window_get_size()
	# Si résolution actuelle pas dedans → on l’ajoute
	if not current in available_resolutions:
		available_resolutions.insert(0, current)
		
	for res in available_resolutions:
		opt_resolution.add_item("%d × %d" % [res.x, res.y])

	# Select current resolution
	var current_res := DisplayServer.window_get_size()
	for i in range(available_resolutions.size()):
		if available_resolutions[i] == current_res:
			opt_resolution.selected = i
			break


func _process(_delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_new_map_button_pressed() -> void:
	$WindowNewMap.popup_centered()


func _on_open_map_button_pressed() -> void:
	# On rafraîchit la liste à chaque ouverture
	_refresh_map_list()
	$WindowOpenMap.popup_centered()


func _on_create_new_map_button_pressed() -> void:
	var spin := $WindowNewMap/VBoxContainer/HBoxContainer/SpinBox
	var line := $WindowNewMap/VBoxContainer/HBoxContainer3/LineEdit

	var map_radius: int = spin.value
	var minimum_radius: int = spin.min_value
	var map_name: String = line.text.strip_edges()

	if map_radius <= 0:
		DialogUtils.error(get_tree().current_scene, "Le radius doit être supérieur à %d." % minimum_radius)
		return

	if map_name == "":
		DialogUtils.error(get_tree().current_scene, "Le nom de la carte est obligatoire")
		return

	# Création du fichier
	FileManager.create_map_file(map_radius, map_name)

	$WindowNewMap.hide()

	# Ouvre directement la nouvelle carte dans MapEditor
	var map_path := "user://maps/%s.json" % map_name
	_open_map_scene(map_path)


func _on_window_open_map_ready() -> void:
	# Si tu as connecté le signal "ready" de WindowOpenMap, on rafraîchit
	_refresh_map_list()


func _refresh_map_list() -> void:
	var map_list: ItemList = $WindowOpenMap/VBoxContainer/MapList
	map_list.clear()

	var dir := DirAccess.open("user://maps/")
	if dir == null:
		return

	dir.list_dir_begin()
	var file := dir.get_next()

	while file != "":
		if file.ends_with(".json"):
			map_list.add_item(file)
		file = dir.get_next()

	dir.list_dir_end()


func _on_do_open_map_button_pressed() -> void:
	var map_list: ItemList = $WindowOpenMap/VBoxContainer/MapList
	var selected := map_list.get_selected_items()

	if selected.size() == 0:
		DialogUtils.error(get_tree().current_scene, "Veuillez sélectionner une carte")
		return

	var filename: String = map_list.get_item_text(selected[0])
	var map_path := "user://maps/%s" % filename

	$WindowOpenMap.hide()
	_open_map_scene(map_path)


# -------------------------------------------------------
#  OUVERTURE RÉELLE DE LA SCÈNE MapEditor
# -------------------------------------------------------
func _open_map_scene(map_path: String) -> void:
	var scene := load("res://scenes/editor/MapEditor.tscn") as PackedScene
	if scene == null:
		DialogUtils.error(get_tree().current_scene, "Impossible de charger MapEditor.tscn")
		return

	var map_editor := scene.instantiate() as MapEditor
	if map_editor == null:
		DialogUtils.error(get_tree().current_scene, "La scène MapEditor n’a pas le bon script")
		return

	map_editor.map_file_path = map_path

	var tree := get_tree()
	var root := tree.root
	var current := tree.current_scene

	root.add_child(map_editor)
	tree.current_scene = map_editor

	if current:
		current.queue_free()


func _on_window_new_map_close_requested() -> void:
	$WindowNewMap.hide()


func _on_window_open_map_close_requested() -> void:
	$WindowOpenMap.hide()


func _on_window_video_close_requested() -> void:
	$WindowVideo.hide()


func _on_video_button_pressed() -> void:
	$WindowVideo.popup_centered()


func _on_apply_button_pressed() -> void:
	if chk_fullscreen.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if chk_vsync.button_pressed else DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(available_resolutions[opt_resolution.selected])
	_save_settings()
	$WindowVideo.hide()
