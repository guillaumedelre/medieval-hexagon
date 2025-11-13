extends Node3D

class_name HexGrid

@export var radius: int = 30
@export var tile_size: float = 1.0
@export var hover_color: Color = Color(1, 1, 0, 0.5)
@export var base_color: Color = Color(0.6, 0.6, 0.6, 0.1)

var tiles: Dictionary = {}
var hovered_key: String = ""

func _ready() -> void:
	_generate_grid()

func _generate_grid() -> void:
	# --- Génération de la grille visible ---
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if abs(q + r) <= radius:
				var mi: MeshInstance3D = MeshInstance3D.new()
				mi.mesh = _create_hex_mesh()
				mi.material_override = _make_material(base_color)
				mi.position = _axial_to_world(q, r)
				add_child(mi)
				tiles["%s:%s" % [q, r]] = mi

	# ---  Plan de collision invisible ---
	# Permet au raycast de détecter le sol même sans tuiles posées.
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "GroundCollider"

	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(radius * tile_size * 3.0, 0.1, radius * tile_size * 3.0)
	shape.shape = box

	body.add_child(shape)
	add_child(body)

func _create_hex_mesh() -> ArrayMesh:
	var local_radius: float = tile_size * 0.5
	var points: PackedVector3Array = PackedVector3Array()
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * float(i))
		points.append(Vector3(local_radius * cos(angle), 0.0, local_radius * sin(angle)))
	points.append(points[0])
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		st.add_vertex(p)
	return st.commit()

func _make_material(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	return mat

func _axial_to_world(q: int, r: int) -> Vector3:
	var x: float = tile_size * sqrt(3.0) * (float(q) + float(r) / 2.0)
	var z: float = tile_size * 1.5 * float(r)
	return Vector3(x, 0.02, z)

func highlight(q: int, r: int) -> void:
	var key: String = "%s:%s" % [q, r]
	if q == -999 and r == -999:
		if tiles.has(hovered_key):
			var prev: MeshInstance3D = tiles[hovered_key]
			prev.material_override.albedo_color = base_color
		hovered_key = ""
		return
	if hovered_key == key:
		return
	if tiles.has(hovered_key):
		var old: MeshInstance3D = tiles[hovered_key]
		old.material_override.albedo_color = base_color
	if tiles.has(key):
		var cur: MeshInstance3D = tiles[key]
		cur.material_override.albedo_color = hover_color
	hovered_key = key
