extends Control
class_name TileBrowser

signal model_selected(path: String)

@onready var grid: GridContainer = $Panel/Scroll/Grid

const MODEL_ROOT: String = "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf"
const PREVIEW_SIZE: Vector2 = Vector2(180, 180)

var models: Array[String] = []
var filter_folder: String = ""   # sous-dossier actif

func _ready() -> void:
	set_filter("")  # affiche tout par défaut

# ---------------------------------------------------------------------
# 🔍 Applique un filtre par sous-dossier
# subfolder = "tiles", "buildings", "decoration" ou ""
# ---------------------------------------------------------------------
func set_filter(subfolder: String) -> void:
	filter_folder = subfolder
	_load_all_models()

# ---------------------------------------------------------------------
# 🔄 Recharge la liste selon le filtre
# ---------------------------------------------------------------------
func _load_all_models() -> void:
	models.clear()

	if grid == null:
		push_error("❌ Grid non trouvée dans TileBrowser.")
		return

	# Nettoyage UI
	for c: Node in grid.get_children():
		c.queue_free()

	# Détermination du chemin à parcourir
	var base_path := MODEL_ROOT
	if filter_folder != "":
		base_path += "/%s" % filter_folder

	if not DirAccess.dir_exists_absolute(base_path):
		push_warning("⚠️ Dossier introuvable : %s" % base_path)
		return

	_scan_dir_recursive(base_path)

	print("🧩 %d modèles affichés (%s)" % [models.size(), filter_folder])

	for model_path: String in models:
		_add_model_preview(model_path)



# ---------------------------------------------------------------------
# 📁 Scan RÉEL des fichiers filtrés
# ---------------------------------------------------------------------
func _scan_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		var full := "%s/%s" % [path, file_name]

		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_dir_recursive(full)

		else:
			if file_name.ends_with(".gltf") or file_name.ends_with(".glb"):
				models.append(full)

		file_name = dir.get_next()

	dir.list_dir_end()



# ---------------------------------------------------------------------
# 🧱 Ajoute un preview + label à la grille
# ---------------------------------------------------------------------
func _add_model_preview(model_path: String) -> void:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = PREVIEW_SIZE
	vb.mouse_filter = Control.MOUSE_FILTER_STOP
	vb.focus_mode = Control.FOCUS_NONE

	var preview_scene: PackedScene = preload("res://scenes/ModelPreview.tscn")
	var preview: ModelPreview = preview_scene.instantiate() as ModelPreview
	preview.model_path = model_path
	vb.add_child(preview)

	var label := Label.new()
	label.text = model_path.get_file().trim_suffix(".gltf").trim_suffix(".glb").trim_prefix("hex_")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	label.add_theme_font_size_override("font_size", 16)
	vb.add_child(label)

	vb.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("✅ Sélectionné :", model_path)
				emit_signal("model_selected", model_path)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				print("🪶 Clic droit sur :", model_path)
	)

	grid.add_child(vb)
