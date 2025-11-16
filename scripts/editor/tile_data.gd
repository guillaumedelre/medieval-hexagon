extends Node3D
class_name HexTile

@export_enum("grass", "water", "coast", "mountain")
var terrain_type: String = "grass"
@export var q: int = 0
@export var r: int = 0


func set_terrain(t: String) -> void:
	terrain_type = t
	var path: String = get_model_path()
	_load_model(path)

func set_custom_model(path: String) -> void:
	_load_model(path)

func get_model_path() -> String:
	match terrain_type:
		"grass":
			return "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.gltf"
		"water":
			return "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_water.gltf"
		"coast":
			return "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/coast/hex_coast_A.gltf"
		"mountain":
			return "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass_sloped_A.gltf"
		_:
			return "res://addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.gltf"

func _load_model(path: String) -> void:
	var scene: PackedScene = load(path)
	if scene == null:
		push_error("️ Impossible de charger : %s" % path)
		return
	for c in get_children():
		if c is Node3D:
			c.queue_free()
	var inst: Node3D = scene.instantiate() as Node3D
	add_child(inst)
	if not has_node("Collider"):
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "Collider"
		var shape: CollisionShape3D = CollisionShape3D.new()
		var cyl: CylinderShape3D = CylinderShape3D.new()
		cyl.radius = 0.9
		cyl.height = 0.1
		shape.shape = cyl
		body.add_child(shape)
		add_child(body)
