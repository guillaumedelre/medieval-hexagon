extends Node3D
class_name GhostTile

@export var model_path: String = ""
@onready var holder: Node3D = $Holder

# --- Couleurs selon l'état ---
const COLOR_OK := Color(0.2, 1.0, 0.2, 0.35)      # vert translucide
const COLOR_BLOCKED := Color(1.0, 0.2, 0.2, 0.35) # rouge translucide

# --- Matériaux pré-générés ---
var mat_ok: StandardMaterial3D
var mat_blocked: StandardMaterial3D

func _ready() -> void:
	mat_ok = _make_tint_material(COLOR_OK)
	mat_blocked = _make_tint_material(COLOR_BLOCKED)

# ---------------------------------------------------------------------
# Charge le modèle si différent de celui déjà en mémoire
# ---------------------------------------------------------------------
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
		push_warning("Impossible de charger le modèle : %s" % path)
		return

	var inst: Node3D = scene.instantiate() as Node3D
	holder.add_child(inst)

	# Applique la teinte par défaut (placable)
	_tint_all_meshes(inst, mat_ok)

# ---------------------------------------------------------------------
# Met à jour la couleur du ghost selon la validité du placement
# ---------------------------------------------------------------------
func set_placeable(can_place: bool) -> void:
	var tint_mat := mat_ok if can_place else mat_blocked
	for c in holder.get_children():
		_tint_all_meshes(c, tint_mat)

# ---------------------------------------------------------------------
# Crée un matériau transparent teinté, qui sert de couche colorée
# ---------------------------------------------------------------------
func _make_tint_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.flags_unshaded = false
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.albedo_color = color
	mat.render_priority = 1
	return mat

# ---------------------------------------------------------------------
# Applique la teinte sans supprimer la texture du matériau original
# ---------------------------------------------------------------------
func _tint_all_meshes(n: Node, tint_mat: StandardMaterial3D) -> void:
	if n is MeshInstance3D:
		var mesh_instance := n as MeshInstance3D
		for i in range(mesh_instance.mesh.get_surface_count()):
			var mat := mesh_instance.get_active_material(i)
			if mat:
				# On clone le matériau d'origine pour garder la texture
				var clone := mat.duplicate()
				clone.flags_transparent = true
				clone.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				clone.render_priority = 1
				# On multiplie la couleur de base par la teinte choisie
				clone.albedo_color = clone.albedo_color.blend(tint_mat.albedo_color)
				mesh_instance.set_surface_override_material(i, clone)
			else:
				mesh_instance.material_override = tint_mat

	for child in n.get_children():
		_tint_all_meshes(child, tint_mat)
