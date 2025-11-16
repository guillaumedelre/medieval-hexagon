extends Node3D
class_name MapEditor

@export var map_file_path: String = "" # ← chemin de la carte (user://maps/xxx.json)

@onready var tile_browser: TileBrowser = $UI/VBoxContainer/FoldableTiles/VBoxContainer/TileBrowser
@onready var layer_tab_bar: TabBar = $UI/VBoxContainer/FoldableTiles/VBoxContainer/LayerTabBar
@onready var hex_grid: HexGrid = $HexGrid
@onready var ghost_tile: GhostTile = $GhostTile
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var terrain_layer: Node3D = $Layers/TerrainLayer
@onready var building_layer: Node3D = $Layers/BuildingLayer
@onready var resource_layer: Node3D = $Layers/ResourceLayer

var current_layer: Node3D
var current_layer_name: String = ""
var current_model_path: String = ""
var map_name: String = ""
var tiles: Dictionary = {} # clé: layer:q:r
var ghost_rotation_deg: float = 0.0
var map_data: Dictionary

func _ready() -> void:
	current_layer = terrain_layer

	if tile_browser and not tile_browser.is_connected("model_selected", Callable(self, "_on_model_selected")):
		tile_browser.model_selected.connect(Callable(self, "_on_model_selected"))

	if not $UI.is_connected("layer_changed", Callable(self, "_on_layer_changed")):
		$UI.layer_changed.connect(Callable(self, "_on_layer_changed"))
		# Simule un clic sur "Terrain" au démarrage
		layer_tab_bar.current_tab = 0
		layer_tab_bar.emit_signal("tab_changed", 0)

	# Si un fichier de carte est défini → on le charge
	if map_file_path != "":
		load_map(map_file_path)

	print("✅ MapEditor prêt.")


func _physics_process(_delta: float) -> void:
	_update_highlight()


func _unhandled_input(event: InputEvent) -> void:
	# --- ANNULATION DU PLACEMENT ---
	if event.is_action_pressed("ui_cancel"):
		if current_model_path != "":
			print("❌ Placement annulé")

			current_model_path = ""
			ghost_rotation_deg = 0.0

			if ghost_tile:
				ghost_tile.visible = false
				ghost_tile.rotation.y = 0.0
			return # empêcher les autres actions
	
	if event is InputEventMouseButton and event.pressed:
		# Empêcher les clics pendant que la souris est sur l’UI
		if get_viewport().gui_get_hovered_control() != null:
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place_tile_from_mouse()
			MOUSE_BUTTON_RIGHT:
				_remove_tile_from_mouse()
	
	if event is InputEventKey and event.pressed:
		if Input.is_action_pressed("rotate_ghost_horary"):
			if event.shift_pressed:
				ghost_rotation_deg += 60.0
			else:
				ghost_rotation_deg -= 60.0

		ghost_rotation_deg = fmod(ghost_rotation_deg, 360.0)

		if ghost_tile:
			ghost_tile.rotation.y = deg_to_rad(ghost_rotation_deg)

		return


func _on_layer_changed(layer_name: String) -> void:
	current_layer_name = layer_name
	$UI/VBoxContainer/FoldableTiles/VBoxContainer/HBoxContainer/TileLayerValue.text = current_layer_name
	match layer_name:
		"terrain":
			current_layer = terrain_layer
			tile_browser.set_filter("tiles")
		"building":
			current_layer = building_layer
			tile_browser.set_filter("buildings")
		"resource":
			current_layer = resource_layer
			tile_browser.set_filter("decoration")
		_:
			DialogUtils.warning(get_tree().current_scene, "Layer inconnu : %s" % layer_name)
			
	# 🔥 Réinitialisation du modèle actif et du ghost
	current_model_path = ""
	print("🔄 Changement de layer → modèle réinitialisé.")

	if ghost_tile:
		ghost_tile.visible = false
		ghost_tile.set_model("")

	print("📌 Layer actif :", current_layer_name)


func _on_model_selected(path: String) -> void:
	current_model_path = path
	print("🎯 Modèle actif :", path)

	if ghost_tile:
		ghost_tile.visible = true
		ghost_tile.set_model(path)


# -------------------------------------------------------
# 🔥 Raycast grille
# -------------------------------------------------------
func _raycast_from_mouse() -> Dictionary:
	var cam := camera
	if cam == null:
		return {}

	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)

	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()

	params.from = origin
	params.to = origin + dir * 5000.0
	params.collide_with_areas = false
	params.collide_with_bodies = true

	# 🔥 IMPORTANT : la grille est sur la layer 1 → on ne touche QUE ça
	params.collision_mask = 1

	return space.intersect_ray(params)


func _update_highlight() -> void:
	var result := _raycast_from_mouse()
	if result.is_empty():
		hex_grid.highlight(-999, -999)
		if ghost_tile:
			ghost_tile.visible = false
		return

	var hit_pos: Vector3 = result.position
	var axial := HexMath.world_to_axial(hit_pos)
	var q := int(axial.x)
	var r := int(axial.y)

	hex_grid.highlight(q, r)
	var world_pos := HexMath.axial_to_world(q, r)

	# Ghost
	if ghost_tile:
		ghost_tile.visible = current_model_path != ""
		ghost_tile.global_position = world_pos
		ghost_tile.rotation.y = deg_to_rad(ghost_rotation_deg)

		var key := _make_key(current_layer_name, q, r)
		var occupied := tiles.has(key)
		ghost_tile.set_valid_state(not occupied)


func _place_tile_from_mouse() -> void:
	if current_layer_name == "":
		print("⚠️ Aucun layer sélectionné.")
		return
	if current_model_path == "":
		print("⚠️ Aucun modèle sélectionné.")
		return

	var hit := _raycast_from_mouse()
	if hit.is_empty():
		return
	
	var axial := HexMath.world_to_axial(hit.position)
	var q := int(axial.x)
	var r := int(axial.y)

	var key := _make_key(current_layer_name, q, r)
	if tiles.has(key):
		print("🚫 Tuile déjà occupée :", key)
		return

	var scene: PackedScene = load(current_model_path)
	if scene == null:
		DialogUtils.warning(get_tree().current_scene, "Impossible de charger :" % current_model_path)
		return

	var inst: Node3D = scene.instantiate()
	inst.position = HexMath.axial_to_world(q, r)

	# 🔥 AJOUT : applique la rotation du GhostTile si présent
	if ghost_tile:
		inst.rotation = ghost_tile.rotation

	current_layer.add_child(inst)
	tiles[key] = inst

	print("✅ Objet placé sur", current_layer_name, "à", key)


func _remove_tile_from_mouse() -> void:
	var hit := _raycast_from_mouse()
	if hit.is_empty():
		return

	var axial := HexMath.world_to_axial(hit.position)
	var q := int(axial.x)
	var r := int(axial.y)

	var key := _make_key(current_layer_name, q, r)
	if not tiles.has(key):
		print("ℹ️ Rien à supprimer :", key)
		return

	tiles[key].queue_free()
	tiles.erase(key)

	print("🗑️ Supprimé :", key)


func _make_key(layer_name: String, q: int, r: int) -> String:
	return "%s:%d:%d" % [layer_name, q, r]


# -------------------------------------------------------
#  CHARGEMENT D’UNE CARTE JSON
# -------------------------------------------------------
func load_map(_map_file_path: String) -> void:
	if _map_file_path == "":
		DialogUtils.warning(get_tree().current_scene, "load_map appelé sans chemin.")
		return

	var file := FileAccess.open(_map_file_path, FileAccess.READ)
	if file == null:
		DialogUtils.warning(get_tree().current_scene, "Impossible d’ouvrir la carte : %s" % _map_file_path)
		return

	var content := file.get_as_text()
	file.close()

	var parsed: Dictionary = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		DialogUtils.warning(get_tree().current_scene, "Fichier de carte invalide : %s" % _map_file_path)
		return

	map_data = parsed

	if map_data.has("radius"):
		var r := int(map_data["radius"])
		hex_grid.set_grid_radius(r)
		$UI._on_map_loaded(map_data)
		print("📐 Carte chargée, radius =", r)
	else:
		DialogUtils.warning(get_tree().current_scene, "La carte ne contient pas de champ 'radius'.")


func _on_close_map_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")

func _on_save_map_button_pressed() -> void:
	var _tiles: Array = []
	for tile_key in tiles.keys():
		var tile_parts: Array = tile_key.split(":")
		_tiles.append({
			"layer": tile_parts[0],
			"q": tile_parts[1],
			"r": tile_parts[2],
			"orientation": int(rad_to_deg(tiles[tile_key].rotation.y)),
			"model": tiles[tile_key].get_children()[0].mesh.resource_name,
		})
	var _map_data: Dictionary = {
		"version": 1,
		"name": map_data.name,
		"radius": map_data.radius,
		"tiles": _tiles,
	}
		
	FileManager.save_map_file("user://maps/%s.json" % map_data.name, _map_data)

