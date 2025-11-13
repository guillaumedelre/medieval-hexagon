extends Control
class_name ToolbarBrowser

@onready var scroll: ScrollContainer = $ModelList
@onready var root_box: VBoxContainer = $ModelList/VBoxContainer
var generator: TerrainGenerator = null

func _ready() -> void:
	#  Récupère le TerrainGenerator (dans ton MapEditor)
	generator = get_tree().get_first_node_in_group("terrain_generator") as TerrainGenerator
	if generator == null:
		push_warning("️ Aucun node 'terrain_generator' trouvé dans la scène.")

	#  Vide le container avant de tout recharger
	for c in root_box.get_children():
		c.queue_free()

	#  Charge les modèles à partir du répertoire principal
	_load_directory("res://addons/kaykit_medieval_hexagon_pack/Assets/gltf")


func _load_directory(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_warning(" Dossier introuvable : %s" % path)
		return

	# --- En-tête du dossier ---
	var header: Label = Label.new()
	header.text = "📁 " + (path.trim_suffix("/").get_file())
	header.add_theme_color_override("font_color", Color(1, 1, 0))
	header.add_theme_font_size_override("font_size", 16)
	root_box.add_child(header)

	# --- Grille de previews ---
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(520, 0)
	grid.theme_type_variation = "panel"
	root_box.add_child(grid)

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name == "":
			break

		if dir.current_is_dir() and not file_name.begins_with("."):
			_load_directory(path.path_join(file_name))
		elif file_name.ends_with(".gltf"):
			var model_path: String = path.path_join(file_name)
			_add_model_preview(grid, model_path)
	dir.list_dir_end()


func _add_model_preview(container: GridContainer, model_path: String) -> void:
	var preview_scene: PackedScene = preload("res://scenes/ModelPreview.tscn")
	var preview: ModelPreview = preview_scene.instantiate() as ModelPreview

	#  On force la mise à jour du SubViewport
	preview.model_path = model_path
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.custom_minimum_size = Vector2(180, 180)

	#  Clique sur une vignette -> sélection du modèle
	preview.gui_input.connect(_on_preview_input.bind(preview))

	container.add_child(preview)


func _on_preview_input(event: InputEvent, p: ModelPreview) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if generator != null:
			generator.current_model_path = p.model_path
			print(" Modèle sélectionné :", p.model_path)
