extends Node3D
class_name GhostTile
@export var model_path: String = ""
@onready var holder: Node3D = $Holder
func set_model(path: String) -> void:
	if path == model_path and holder.get_child_count() > 0:
		return
	model_path = path
	for c in holder.get_children():
		c.queue_free()
	if path == "":
		return
	var scene: PackedScene = load(path)
	if scene == null:
		return
	var inst: Node3D = scene.instantiate() as Node3D
	_make_transparent(inst)
	holder.add_child(inst)
func _make_transparent(n: Node) -> void:
	if n is MeshInstance3D:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1,1,0,0.4)
		(n as MeshInstance3D).material_override = mat
	for child in n.get_children():
		_make_transparent(child)
