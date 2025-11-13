@tool
extends Control
class_name ModelPreview

@export var model_path: String = "":
	set(value):
		if value == model_path:
			return
		model_path = value
		# ✅ On attend que le node soit prêt avant de charger
		if is_inside_tree():
			_load_model(model_path)
		else:
			call_deferred("_load_model", model_path)

@export var auto_rotate: bool = true
@export var rotation_speed: float = 15.0

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var holder: Node3D = $SubViewportContainer/SubViewport/Holder
@onready var label: Label = $Label

var model_instance: Node3D = null


func _ready() -> void:
	if not model_path.is_empty() and model_instance == null:
		_load_model(model_path)

	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if auto_rotate and model_instance != null:
		model_instance.rotate_y(deg_to_rad(rotation_speed * delta))


# --------------------------------------------------------
# Chargement et centrage du modèle 3D
# --------------------------------------------------------
func _load_model(path: String) -> void:
	if holder == null:
		push_warning("⚠️ 'holder' n'est pas encore initialisé, chargement différé.")
		call_deferred("_load_model", path)
		return

	for c: Node in holder.get_children():
		c.queue_free()
	model_instance = null

	var scene: PackedScene = load(path)
	if scene == null:
		push_error("⚠️ Impossible de charger le modèle : %s" % path)
		return

	var inst: Node3D = scene.instantiate() as Node3D
	holder.add_child(inst)
	model_instance = inst

	# --- Ajustement du modèle ---
	var aabb: AABB = _get_combined_aabb(inst)
	if aabb.size != Vector3.ZERO:
		var center: Vector3 = aabb.get_center()
		inst.position = -center

		var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		var scale_factor: float = 2.5 / max_dim
		inst.scale = Vector3.ONE * scale_factor

	_apply_default_material(inst)

	label.text = path.get_file().get_basename()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


# --------------------------------------------------------
# Combine tous les AABB d’un modèle (multi-meshs inclus)
# --------------------------------------------------------
func _get_combined_aabb(node: Node3D) -> AABB:
	var result: AABB = AABB()
	var has_aabb: bool = false

	for child: Node in node.get_children():
		if child is MeshInstance3D:
			var mesh_aabb: AABB = (child as MeshInstance3D).get_aabb()
			if not has_aabb:
				result = mesh_aabb
				has_aabb = true
			else:
				result = result.merge(mesh_aabb)
		elif child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child as Node3D)
			if sub_aabb.size != Vector3.ZERO:
				if not has_aabb:
					result = sub_aabb
					has_aabb = true
				else:
					result = result.merge(sub_aabb)
	return result


# --------------------------------------------------------
# Donne un matériau par défaut si manquant
# --------------------------------------------------------
func _apply_default_material(node: Node) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override == null:
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = Color(0.8, 0.8, 0.8)
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			(child as MeshInstance3D).material_override = mat
		if child is Node:
			_apply_default_material(child)
