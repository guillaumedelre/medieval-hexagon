extends Node3D
class_name GhostTile

@export var model_path: String = ""
@onready var holder: Node3D = $Holder

# Matériaux mémorisés pour réutiliser la même teinte
var mat_ok: StandardMaterial3D
var mat_blocked: StandardMaterial3D
var can_place: bool = true


func _ready() -> void:
	# Matériaux verts / rouges semi-transparents
	mat_ok = StandardMaterial3D.new()
	mat_ok.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_ok.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ok.albedo_color = Color(0.4, 1.0, 0.4, 0.4)

	mat_blocked = StandardMaterial3D.new()
	mat_blocked.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_blocked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_blocked.albedo_color = Color(1.0, 0.3, 0.3, 0.4)


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
		push_warning("⚠️ Modèle introuvable : %s" % path)
		return

	var inst: Node3D = scene.instantiate()
	_make_transparent(inst)
	holder.add_child(inst)


func _make_transparent(n: Node) -> void:
	if n is MeshInstance3D:
		var mesh := n as MeshInstance3D
		# copie du matériel original pour garder la texture mais ajouter transparence
		var base_mat: BaseMaterial3D
		if mesh.material_override and mesh.material_override is BaseMaterial3D:
			base_mat = mesh.material_override.duplicate() as BaseMaterial3D
		else:
			base_mat = StandardMaterial3D.new()

		base_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		base_mat.albedo_color.a = 0.4
		base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = base_mat

	for child in n.get_children():
		_make_transparent(child)


# ✅ Change la teinte du modèle selon s’il est plaçable ou non
func set_valid_state(value: bool) -> void:
	can_place = value
	var tint_mat := mat_ok if can_place else mat_blocked
	_apply_tint(holder, tint_mat)


func _apply_tint(n: Node, tint: StandardMaterial3D) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = tint
	for child in n.get_children():
		_apply_tint(child, tint)
