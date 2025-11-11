extends Node3D
class_name TerrainGenerator
const HexTileScene: PackedScene = preload("res://scenes/HexTile.tscn")
@onready var math: HexMath = preload("res://scripts/hex_math.gd").new()
@onready var grid: HexGrid = preload("res://scenes/HexGrid.tscn").instantiate() as HexGrid
@onready var ghost_tile: GhostTile = preload("res://scenes/GhostTile.tscn").instantiate() as GhostTile
var tiles: Dictionary = {}
var current_type: String = "grass"
var current_model_path: String = ""
var click_left_pending: bool = false
var click_right_pending: bool = false
func _ready() -> void:
	add_child(grid)
	add_child(ghost_tile)
	ghost_tile.visible = false
	add_to_group("terrain_generator")
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
			MOUSE_BUTTON_LEFT:
				click_left_pending = true
			MOUSE_BUTTON_RIGHT:
				click_right_pending = true
func _update_highlight() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var dir: Vector3 = cam.project_ray_normal(mouse_pos)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty():
		grid.highlight(-999, -999)
		ghost_tile.visible = false
		return
	var hit_pos: Vector3 = result.position
	var axial: Vector2 = math.world_to_axial(hit_pos)
	var q: int = int(axial.x)
	var r: int = int(axial.y)
	grid.highlight(q, r)
	var world_pos: Vector3 = math.axial_to_world(q, r)
	ghost_tile.visible = true
	ghost_tile.position = world_pos
	if current_model_path != "":
		ghost_tile.set_model(current_model_path)
func _place_tile_from_mouse() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var dir: Vector3 = cam.project_ray_normal(mouse_pos)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty():
		return
	var hit_pos: Vector3 = result.position
	var axial: Vector2 = math.world_to_axial(hit_pos)
	_place_tile(int(axial.x), int(axial.y))
func _remove_tile_from_mouse() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var dir: Vector3 = cam.project_ray_normal(mouse_pos)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2000.0)
	params.collide_with_bodies = true
	var result: Dictionary = space.intersect_ray(params)
	if result.is_empty():
		return
	var hit_pos: Vector3 = result.position
	var axial: Vector2 = math.world_to_axial(hit_pos)
	_remove_tile(int(axial.x), int(axial.y))
func _place_tile(q: int, r: int) -> void:
	var key: String = "%s:%s" % [q, r]
	if tiles.has(key):
		var existing: HexTile = tiles[key]
		if current_model_path != "":
			existing.set_custom_model(current_model_path)
		else:
			existing.set_terrain(current_type)
		return
	var tile: HexTile = HexTileScene.instantiate() as HexTile
	tile.q = q
	tile.r = r
	if current_model_path != "":
		tile.set_custom_model(current_model_path)
	else:
		tile.set_terrain(current_type)
	tile.position = math.axial_to_world(q, r)
	add_child(tile)
	tiles[key] = tile
func _remove_tile(q: int, r: int) -> void:
	var key: String = "%s:%s" % [q, r]
	if not tiles.has(key):
		return
	var tile: Node3D = tiles[key]
	if tile:
		tile.queue_free()
		tiles.erase(key)
