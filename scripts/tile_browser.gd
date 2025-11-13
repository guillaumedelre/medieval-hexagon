extends Control
class_name TileBrowser

signal model_selected(path: String)

@onready var grid: GridContainer = $Panel/Scroll/Grid

const MODEL_ROOT: String = "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf"
const PREVIEW_SIZE: Vector2 = Vector2(180, 180)

var models: Array[String] = []


func _ready() -> void:
	_load_all_models()


# ---------------------------------------------------------------------
# 🔍 Recherche récursive des .gltf / .glb dans le dossier spécifié
# ---------------------------------------------------------------------
func _load_all_models() -> void:
	models.clear()
	if grid == null:
		push_error("❌ Grid non trouvée dans TileBrowser.")
		return

	for c: Node in grid.get_children():
		c.queue_free()

	if not DirAccess.dir_exists_absolute(MODEL_ROOT):
		push_warning("⚠️ Le dossier d’assets n’existe pas : %s" % MODEL_ROOT)
		return

	_scan_dir_recursive(MODEL_ROOT)
	print("🧩 %d modèles détectés." % models.size())

	for model_path: String in models:
		_add_model_preview(model_path)


func _scan_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_dir_recursive("%s/%s" % [path, file_name])
		elif file_name.ends_with(".gltf") or file_name.ends_with(".glb"):
			models.append("%s/%s" % [path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()


# ---------------------------------------------------------------------
# 🧱 Création d’un aperçu cliquable pour chaque modèle
# ---------------------------------------------------------------------
func _add_model_preview(model_path: String) -> void:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = PREVIEW_SIZE
	vb.mouse_filter = Control.MOUSE_FILTER_STOP
	vb.focus_mode = Control.FOCUS_NONE

	# --- Chargement du preview 3D ---
	var preview_scene: PackedScene = preload("res://scenes/ModelPreview.tscn")
	var preview: ModelPreview = preview_scene.instantiate() as ModelPreview
	preview.model_path = model_path
	vb.add_child(preview)

	# --- Label du nom de fichier ---
	var label := Label.new()
	label.text = model_path.get_file().trim_suffix(".gltf").trim_suffix(".glb")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vb.add_child(label)

	# --- Gestion des clics ---
	vb.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("✅ Sélectionné :", model_path)
				emit_signal("model_selected", model_path)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				print("🪶 Clic droit sur :", model_path)
	)

	grid.add_child(vb)
