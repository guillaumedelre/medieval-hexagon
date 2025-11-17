extends Node3D
class_name DayNightCycle

# Pivots Soleil / Lune
@export var sun_pivot: Node3D
@export var moon_pivot: Node3D
@export var world_env: WorldEnvironment

# 🎯 Centre de la grille (ex: axial_to_world(0,0))
@export var grid_center: Vector3 = Vector3.ZERO

@export var day_length_seconds := 180.0

# Astres
const SUN_SIZE := 100.0
const MOON_SIZE := 10.0
const ORBIT_RADIUS := 5000.0
const NO_SHADOW_LAYER := 99

var time := 0.25

# Soleil
var sun_mesh: MeshInstance3D
var sun_light: DirectionalLight3D

# Lune
var moon_mesh: MeshInstance3D
var moon_light: DirectionalLight3D


# ======================================================
# READY
# ======================================================
func _ready() -> void:
	print("☀️ DayNightCycle Loaded")

	if sun_pivot == null:
		sun_pivot = get_node("SunPivot")
	if moon_pivot == null:
		moon_pivot = get_node("MoonPivot")

	_create_sun()
	_create_moon()


# ======================================================
# PROCESS
# ======================================================
func _process(delta: float) -> void:
	time = fmod(time + delta / day_length_seconds, 1.0)

	var phi := (time - 0.25) * TAU

	var sun_dir := Vector3(0, sin(phi), cos(phi)).normalized()
	var moon_dir := -sun_dir

	var sun_pos := sun_dir * ORBIT_RADIUS
	var moon_pos := moon_dir * ORBIT_RADIUS

	sun_pivot.global_position = sun_pos
	moon_pivot.global_position = moon_pos

	_update_light(sun_light, sun_pos)
	_update_light(moon_light, moon_pos)

	var sun_strength: float = clamp(sun_dir.y, 0.0, 1.0)

	# Zelda-style atmosphere
	_update_environment(sun_strength)
	_update_sky(sun_strength)
	_update_fog(sun_strength)
	_update_dusk_color(sun_strength)
	_update_bloom()


# ======================================================
# UPDATE LIGHTS + ARROWS
# ======================================================
func _update_light(_light: DirectionalLight3D, _pos: Vector3) -> void:
	_light.global_position = _pos
	_light.look_at(grid_center, Vector3.UP)


# ======================================================
# CREATION : SOLEIL
# ======================================================
func _create_sun() -> void:
	sun_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = SUN_SIZE
	sun_mesh.mesh = sphere
	# empeche la projection de l'ombre de la sphere sur le sol
	sun_mesh.layers = 1 << NO_SHADOW_LAYER

	sun_mesh.material_override = _make_emissive(Color(1.2, 1.1, 0.6), 3.0)
	sun_mesh.material_override.no_depth_test = true

	sun_pivot.add_child(sun_mesh)

	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_energy = 1.0
	sun_light.shadow_enabled = true
	sun_light.shadow_blur = 5.0
	sun_light.light_cull_mask = ~ (1 << NO_SHADOW_LAYER)

	sun_mesh.add_child(sun_light)


# ======================================================
# CREATION : LUNE
# ======================================================
func _create_moon() -> void:
	moon_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = MOON_SIZE
	moon_mesh.mesh = sphere
	# empeche la projection de l'ombre de la sphere sur le sol
	moon_mesh.layers = 1 << NO_SHADOW_LAYER

	moon_mesh.material_override = _make_emissive(Color(0.7, 0.8, 1.0), 1.0)
	moon_mesh.material_override.no_depth_test = true

	moon_pivot.add_child(moon_mesh)

	moon_light = DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_energy = 0.2
	moon_light.shadow_enabled = true
	moon_light.shadow_blur = 5.0
	moon_light.light_cull_mask = ~ (1 << NO_SHADOW_LAYER)

	moon_mesh.add_child(moon_light)


# ======================================================
# MATERIAL UTIL
# ======================================================
func _make_emissive(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


# ======================================================
# ENVIRONMENT (AMBIENT LIGHT)
# ======================================================
func _update_environment(strength: float) -> void:
	if world_env == null: return
	var env := world_env.environment
	if env == null: return

	env.ambient_light_energy = lerp(0.05, 0.25, strength)
	env.ambient_light_color = Color(0.1, 0.12, 0.20).lerp(Color.WHITE, strength)


# ======================================================
# SKY ≈ BOTW Blue Sky Gradient
# ======================================================
func _update_sky(strength: float) -> void:
	if world_env == null: return
	var env := world_env.environment
	if env == null: return

	var sky := env.sky
	if sky == null: return

	var mat := sky.sky_material
	if mat == null: return

	if mat is ProceduralSkyMaterial:
		var p := mat as ProceduralSkyMaterial
		p.sky_top_color = Color(0.05, 0.06, 0.12).lerp(Color(0.4, 0.6, 1.0), strength)
		p.sky_horizon_color = Color(0.1, 0.12, 0.20).lerp(Color(0.5, 0.7, 1.0), strength)
		p.energy_multiplier = max(0.1, strength)


# ======================================================
# FOG DYNAMIQUE STYLE BOTW
# ======================================================
func _update_fog(strength: float) -> void:
	var env := world_env.environment

	# Activer le fog
	env.fog_enabled = true
	
	# Fog "léger" = BOTW style
	# Couleur du fog : bleu clair le jour, bleu foncé la nuit
	env.fog_light_color = Color(0.08, 0.10, 0.16).lerp(Color(0.6, 0.7, 1.0), strength)

	# Force du fog
	env.fog_light_energy = lerp(0.3, 1.4, strength)

	# Ajout d’un fog atmosphérique global
	env.fog_density = lerp(0.015, 0.001, strength)

	# Influence du ciel sur le fog
	env.fog_sky_affect = lerp(0.1, 0.6, strength)


# ======================================================
# COULEURS DU CREPUSCULE STYLE BOTW
# ======================================================
func _update_dusk_color(sun_strength: float) -> void:
	var env := world_env.environment
	if env == null: return

	var sky := env.sky
	if sky == null: return
	var mat := sky.sky_material
	if mat == null: return
	if not (mat is ProceduralSkyMaterial): return

	var p := mat as ProceduralSkyMaterial

	# ----------------------------------------------------
	# Crépuscule : moment où le soleil est proche de 0° 
	# (sun_strength proche de 0 mais pas encore négatif)
	# ----------------------------------------------------

	# dusk_factor = 1.0 lorsque sun_strength ≈ 0.15
	# dusk_factor = 0.0 lorsque sun_strength = 0 ou 0.5
	var dusk_factor: float = clamp(1.0 - abs(sun_strength - 0.15) * 6.0, 0.0, 1.0)

	# 🌤 Couleurs "jour" (base)
	var normal_top := Color(0.4, 0.6, 1.0)
	var normal_horizon := Color(0.5, 0.7, 1.0)

	# 🌇 Couleurs crépuscule
	var dusk_top := Color(0.9, 0.4, 0.2)
	var dusk_horizon := Color(1.0, 0.55, 0.25)

	# Blend sky → dusk
	p.sky_top_color = normal_top.lerp(dusk_top, dusk_factor * 0.8)
	p.sky_horizon_color = normal_horizon.lerp(dusk_horizon, dusk_factor)

	# Option : renforcer l’horizon en bas
	#p.ground_horizon_color = Color(0.8, 0.4, 0.3).lerp(Color(0.3, 0.3, 0.3), dusk_factor)


# ======================================================
# BLOOM / HALO ATMOSPHERIQUE
# ======================================================
func _update_bloom() -> void:
	# Pas besoin de code : activer dans Project Settings:
	# Rendering → Glow → Enabled
	pass
