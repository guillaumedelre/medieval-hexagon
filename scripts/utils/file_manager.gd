extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func create_map_file(map_radius: int, map_name: String) -> void:
	var dir := DirAccess.open("user://")

	# Créer un dossier maps si inexistant
	if not dir.dir_exists("maps"):
		dir.make_dir("maps")

	# Construire le JSON
	var map_data := {
		"radius": map_radius,
		"name": map_name,
		"tiles": [] # tu pourras ajouter ton contenu ici
	}

	var file_path := "user://maps/%s.json" % map_name
	save_map_file(file_path, map_data)

func load_map_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		DialogUtils.error(get_tree().current_scene, "Impossible d'ouvrir le fichier map")
		return {}
	
	var text := file.get_as_text()
	file.close()

	var result: Dictionary = JSON.parse_string(text)
	if result == null:
		DialogUtils.error(get_tree().current_scene, "Fichier map invalide")
		return {}

	return result


func save_map_file(file_path: String, map_data: Dictionary) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		DialogUtils.error(get_tree().current_scene, "Impossible de sauvegarder la carte")
		return

	file.store_string(JSON.stringify(map_data, "\t"))
	file.close()
	DialogUtils.success(get_tree().current_scene, "Carte sauvegardée")
