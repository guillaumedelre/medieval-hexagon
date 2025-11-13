extends Node3D
class_name TerrainGenerator

const HexTileScene: PackedScene = preload("res://scenes/HexTile.tscn")

@onready var math: Node = preload("res://scripts/hex_math.gd").new()
@onready var grid: Node3D = preload("res://scenes/HexGrid.tscn").instantiate()
@onready var ghost_tile: Node3D = preload("res://scenes/GhostTile.tscn").instantiate()
@onready var map_editor: Node = preload("res://scripts/map_editor.gd").new()

var tiles: Dictionary = {}
var current_model_path: String = ""
var current_type: String = "grass"
var click_left_pending: bool = false
var click_right_pending: bool = false

func _ready() -> void:
	add_child(map_editor)
	add_child(grid)
	add_child(ghost_tile)
	ghost_tile.visible = false
	add_to_group("terrain_generator")
	print("🌍 Terrain prêt.")


# -------------------------------------------------------------------
# Sélection du modèle depuis ToolbarBrowser
# -------------------------------------------------------------------
func _on_model_selected(path: String) -> void:
	current_model_path = path
	if ghost_tile:
		ghost_tile.visible = true
		ghost_tile.set_model(path)
	print("📦 Modèle actif :", path)


# -------------------------------------------------------------------
# Placement des tuiles
# -------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	_update_highlight()
	if click_left_pending:
		_place_tile_from_mouse()
		click_left_pending = false
	elif click_right_pending:
		_remove_tile_from_mouse()
		click_right_pending = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:  click_left_pending = true
			MOUSE_BUTTON_RIGHT: click_right_pending = true


func _update_highlight() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null: return

	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		grid.highlight(-999, -999)
		ghost_tile.visible = false
		return

	var hit_pos : Vector3 = hit.position
	var axial : Vector2 = math.world_to_axial(hit_pos)
	var q := int(axial.x)
	var r := int(axial.y)
	grid.highlight(q, r)
	var world_pos : Vector3 = math.axial_to_world(q, r)

	if ghost_tile:
		ghost_tile.position = world_pos
		# Rouge si déjà occupé
		var key := "%s:%s" % [q, r]
		var occupied := tiles.has(key)
		ghost_tile.set_valid_state(!occupied)


func _place_tile_from_mouse() -> void:
	if current_model_path == "":
		print("⚠️ Aucun modèle sélectionné.")
		return

	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null: return

	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	if hit.is_empty(): return

	var hit_pos : Vector3 = hit.position
	var axial : Vector2 = math.world_to_axial(hit_pos)
	var q := int(axial.x)
	var r := int(axial.y)

	var key := "%s:%s" % [q, r]
	if tiles.has(key):
		print("🚫 Tuile déjà occupée en (%s, %s)" % [q, r])
		return

	_place_tile(q, r)
	current_model_path = ""
	ghost_tile.visible = false

func _place_tile(q: int, r: int) -> void:
	var key := "%s:%s" % [q, r]
	var tile := HexTileScene.instantiate()
	tile.q = q
	tile.r = r
	if current_model_path != "":
		tile.set_custom_model(current_model_path)
	else:
		tile.set_terrain(current_type)
	tile.position = math.axial_to_world(q, r)
	add_child(tile)
	tiles[key] = tile
	print("✅ Tuile placée :", key)


func _remove_tile_from_mouse() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null: return
	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	if hit.is_empty(): return

	var hit_pos : Vector3 = hit.position
	var axial : Vector2 = math.world_to_axial(hit_pos)
	var q := int(axial.x)
	var r := int(axial.y)
	var key := "%s:%s" % [q, r]
	if tiles.has(key):
		tiles[key].queue_free()
		tiles.erase(key)
		print("🗑️ Tuile supprimée :", key)
