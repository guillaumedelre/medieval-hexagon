extends Node3D
class_name GhostTile

@onready var holder: Node3D = $Holder

var model_path: String = ""
var mesh_ok: StandardMaterial3D
var mesh_blocked: StandardMaterial3D

func _ready() -> void:
	mesh_ok = StandardMaterial3D.new()
	mesh_ok.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_ok.albedo_color = Color(0, 1, 0, 0.35)

	mesh_blocked = StandardMaterial3D.new()
	mesh_blocked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_blocked.albedo_color = Color(1, 0, 0, 0.35)


func clear() -> void:
	for c in holder.get_children():
		c.queue_free()
	model_path = ""


func set_model(path: String) -> void:
	if path == model_path:
		return
	clear()
	model_path = path

	var scene: PackedScene = load(path)
	if not scene:
		return

	var inst: Node3D = scene.instantiate()
	holder.add_child(inst)
	_apply_material(inst, mesh_ok)


func set_valid_state(is_ok: bool) -> void:
	var mat = mesh_ok if is_ok else mesh_blocked
	for c in holder.get_children():
		_apply_material(c, mat)


func _apply_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material(child, mat)
