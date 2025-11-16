extends Node3D
class_name HexGrid

# -------------------------------------------------------------------
# PARAMÈTRES
# -------------------------------------------------------------------
@export var grid_radius: int = 40 # rayon de la grille (axial)
@export var tile_size: float = 1.1547 # taille d’un hex
@export var outline_color: Color = Color(1, 1, 1, 0.01)
@onready var mm_instance: MultiMeshInstance3D = $Visual
@onready var collider: StaticBody3D = $Collider
@onready var coll_shape: CollisionShape3D = $Collider/CollisionShape

var mm: MultiMesh # MultiMesh visuel


# -------------------------------------------------------------------
# READY
# -------------------------------------------------------------------
func _ready() -> void:
	# On synchronise la taille des tuiles entre la grille et les maths
	HexMath.TILE_SIZE = tile_size
	_regenerate()


# -------------------------------------------------------------------
# API PUBLIQUE : changer le rayon depuis l’extérieur (MapEditor)
# -------------------------------------------------------------------
func set_grid_radius(new_radius: int) -> void:
	if new_radius == grid_radius:
		return

	grid_radius = new_radius
	_regenerate()


# -------------------------------------------------------------------
# RE-GÉNÈRE TOUT (visuel + collisions)
# -------------------------------------------------------------------
func _regenerate() -> void:
	# Nettoyage
	if mm_instance:
		mm_instance.multimesh = null
	if coll_shape:
		coll_shape.shape = null

	_generate_visual_mesh()
	_generate_collision_mesh()

	if mm:
		print("🌐 HexGrid %d optimisée prête. Instances = %d" % [grid_radius, mm.instance_count])
	else:
		print("⚠️ HexGrid : MultiMesh non généré.")


# -------------------------------------------------------------------
# GENERATION DU MULTIMESH (VISUEL UNIQUEMENT)
# -------------------------------------------------------------------
func _generate_visual_mesh() -> void:
	var mesh: Mesh = _create_hex_outline_mesh(tile_size * 0.98)

	var cells: Array = _generate_axial_list()
	var count: int = cells.size()

	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count

	var i := 0
	for c in cells:
		var cell: Vector2 = c as Vector2
		var q: int = int(cell.x)
		var r: int = int(cell.y)
		var pos: Vector3 = HexMath.axial_to_world(q, r)
		mm.set_instance_transform(i, Transform3D(Basis(), pos))
		i += 1

	mm_instance.multimesh = mm


# -------------------------------------------------------------------
# GENERATION COLLISION (UN SEUL MESH)
# -------------------------------------------------------------------
func _generate_collision_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var cells: Array = _generate_axial_list()

	for c in cells:
		var cell: Vector2 = c as Vector2
		var q: int = int(cell.x)
		var r: int = int(cell.y)
		var center: Vector3 = HexMath.axial_to_world(q, r)
		_add_hex_collision(st, center, tile_size)

	var col_mesh: ArrayMesh = st.commit() as ArrayMesh
	if col_mesh == null:
		DialogUtils.warning(get_tree().current_scene, "HexGrid: échec génération mesh de collision")
		return

	var faces: PackedVector3Array = col_mesh.get_faces()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)

	coll_shape.shape = shape


# -------------------------------------------------------------------
# LISTE DES CELLULES (COORDONNÉES AXIALES)
# -------------------------------------------------------------------
func _generate_axial_list() -> Array:
	var res: Array = []
	for q in range(-grid_radius, grid_radius + 1):
		for r in range(-grid_radius, grid_radius + 1):
			if abs(q + r) <= grid_radius:
				res.append(Vector2(q, r))
	return res


# -------------------------------------------------------------------
# MESH D’UN HEX EN LIGNES (OUTLINE)
# -------------------------------------------------------------------
func _create_hex_outline_mesh(size: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(7):
		var corner: Vector3 = HexMath.hex_corner(size, i % 6)
		st.set_color(outline_color) # alpha respecté via matériau
		st.add_vertex(corner)

	var mesh := st.commit()
	if mesh == null:
		return null

	# --- Matériau transparent obligatoire ---
	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.render_priority = 1 # limite les artefacts

	mesh.surface_set_material(0, mat)

	return mesh


# -------------------------------------------------------------------
# COLLISION : AJOUT D’UN HEX EN TRIANGLES
# -------------------------------------------------------------------
func _add_hex_collision(st: SurfaceTool, center: Vector3, size: float) -> void:
	var pts: Array[Vector3] = []

	for i in range(6):
		var local_corner: Vector3 = HexMath.hex_corner(size, i)
		pts.append(center + local_corner)

	# 4 triangles plats pour former un hexagone
	st.add_vertex(pts[0]); st.add_vertex(pts[1]); st.add_vertex(pts[2])
	st.add_vertex(pts[0]); st.add_vertex(pts[2]); st.add_vertex(pts[3])
	st.add_vertex(pts[0]); st.add_vertex(pts[3]); st.add_vertex(pts[4])
	st.add_vertex(pts[0]); st.add_vertex(pts[4]); st.add_vertex(pts[5])


# -------------------------------------------------------------------
# highlight (hook possible si tu veux un visuel plus tard)
# -------------------------------------------------------------------
func highlight(_q: int, _r: int) -> void:
	pass
