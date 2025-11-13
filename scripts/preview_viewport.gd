@tool
extends Control
class_name ModelPreview

@export var model_path: String = "":
	set(value):
		model_path = value
		if Engine.is_editor_hint() and not model_path.is_empty():
			_load_model(model_path)

@export var auto_rotate: bool = true
@export var rotation_speed: float = 15.0

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var holder: Node3D = $SubViewportContainer/SubViewport/Holder
@onready var label: Label = $Label

var model_instance: Node3D = null


func _ready() -> void:
	if not model_path.is_empty():
		_load_model(model_path)


func _process(delta: float) -> void:
	# --- Rotation automatique de la tuile ---
	if auto_rotate and model_instance != null:
		model_instance.rotate_y(deg_to_rad(rotation_speed * delta))


# --------------------------------------------------------
# Chargement et centrage du modèle 3D
# --------------------------------------------------------
func _load_model(path: String) -> void:
	# Nettoyage du contenu précédent
	for c in holder.get_children():
		c.queue_free()
	model_instance = null

	var scene: PackedScene = load(path)
	if scene == null:
		push_error(" Impossible de charger : %s" % path)
		return

	var inst: Node3D = scene.instantiate() as Node3D
	holder.add_child(inst)
	model_instance = inst

	# --- Ajustement du modèle ---
	var aabb: AABB = _get_combined_aabb(inst)
	if aabb.size != Vector3.ZERO:
		var center: Vector3 = aabb.get_center()
		# On centre et on met à l’échelle de manière uniforme
		inst.position = -center * 0.5
		var max_dim: float = max(aabb.size.x, aabb.size.y, aabb.size.z)
		var scale_factor: float = 2.5 / max_dim
		inst.scale = Vector3.ONE * scale_factor

	label.text = path.get_file().get_basename()

	# --- Forcer une mise à jour du viewport ---
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


# --------------------------------------------------------
# Combine tous les AABB d’un modèle (multi-meshs inclus)
# --------------------------------------------------------
func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var has_aabb := false

	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_aabb: AABB = child.get_aabb()
			if not has_aabb:
				result = mesh_aabb
				has_aabb = true
			else:
				result = result.merge(mesh_aabb)
		elif child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size != Vector3.ZERO:
				if not has_aabb:
					result = sub_aabb
					has_aabb = true
				else:
					result = result.merge(sub_aabb)

	return result
