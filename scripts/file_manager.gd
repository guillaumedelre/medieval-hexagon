extends Node

@onready var dialog_utils := preload("res://scripts/dialog_utils.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _create_map_file(map_radius: int, map_name: String) -> void:
	var dir := DirAccess.open("user://")

	# Créer un dossier maps si inexistant
	if not dir.dir_exists("maps"):
		dir.make_dir("maps")

	# Construire le JSON
	var map_data := {
		"radius": map_radius,
		"name": map_name,
		"tiles": []  # tu pourras ajouter ton contenu ici
	}

	var file_path := "user://maps/%s.json" % map_name

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		dialog_utils._show_error(get_tree().current_scene, "❌ Impossible de créer le fichier map.")
		return

	file.store_string(JSON.stringify(map_data, "\t"))
	file.close()

	print("✅ Carte enregistrée ici :", file_path)


func load_map_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		dialog_utils._show_error(get_tree().current_scene, "❌ Impossible d'ouvrir le fichier map.")
		return {}
	
	var text := file.get_as_text()
	file.close()

	var result :Dictionary = JSON.parse_string(text)
	if result == null:
		dialog_utils._show_error(get_tree().current_scene, "❌ Fichier map invalide.")
		return {}

	return result
