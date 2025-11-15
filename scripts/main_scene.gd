extends Control

@onready var dialog_utils := preload("res://scripts/dialog_utils.gd").new()
@onready var file_manager := preload("res://scripts/file_manager.gd").new()

func _ready() -> void:
	$WindowNewMap.hide()
	$WindowOpenMap.hide()


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
		dialog_utils._show_error(get_tree().current_scene, "Le radius doit être supérieur à %d." % minimum_radius)
		return

	if map_name == "":
		dialog_utils._show_error(get_tree().current_scene, "Le nom de la carte est obligatoire.")
		return

	# Création du fichier
	file_manager._create_map_file(map_radius, map_name)

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
		dialog_utils._show_error(get_tree().current_scene, "Veuillez sélectionner une carte.")
		return

	var filename: String = map_list.get_item_text(selected[0])
	var map_path := "user://maps/%s" % filename

	$WindowOpenMap.hide()
	_open_map_scene(map_path)


# -------------------------------------------------------
#  OUVERTURE RÉELLE DE LA SCÈNE MapEditor
# -------------------------------------------------------
func _open_map_scene(map_path: String) -> void:
	var scene := load("res://scenes/MapEditor.tscn") as PackedScene
	if scene == null:
		dialog_utils._show_error(get_tree().current_scene, "❌ Impossible de charger MapEditor.tscn")
		return

	var map_editor := scene.instantiate() as MapEditor
	if map_editor == null:
		dialog_utils._show_error(get_tree().current_scene, "❌ La scène MapEditor n’a pas le bon script.")
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
