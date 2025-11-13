@tool
extends Control
class_name ModelPreview

@export var model_path: String = "":
	set(value):
		if value == model_path:
			return
		model_path = value
		if model_path.is_empty():
			return
		if is_inside_tree():
			_load_model(model_path)
		else:
			call_deferred("_load_model", model_path)

@export var auto_rotate: bool = true
@export var rotation_speed: float = 15.0

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var holder: Node3D = $SubViewportContainer/SubViewport/Holder

const PREVIEW_SCALE: float = 1    # ↙️ 3x plus petit (0.3 = 30%)

var model_instance: Node3D = null

func _ready() -> void:
	if not model_path.is_empty() and model_instance == null:
		_load_model(model_path)

	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if auto_rotate and model_instance != null:
		model_instance.rotate_y(deg_to_rad(rotation_speed * delta))


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

	var aabb: AABB = _get_combined_aabb(inst)
	if aabb.size != Vector3.ZERO:
		var center: Vector3 = aabb.get_center()
		inst.position = -center

		var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		var scale_factor: float = (2.5 / max_dim) * PREVIEW_SCALE
		inst.scale = Vector3.ONE * scale_factor

	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


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
