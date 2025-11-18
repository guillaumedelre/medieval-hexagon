extends Node3D
class_name DayNightCycle

@export var sun_pivot: Node3D
@export var moon_pivot: Node3D
@export var world_env: WorldEnvironment

@export var grid_center: Vector3 = Vector3.ZERO
@export var day_length_seconds: float = 180.0


const ORBIT_RADIUS := 1000.0

var time: float = 0.0 # 0 = minuit, 0.5 = midi
var sun_light: DirectionalLight3D
var moon_light: DirectionalLight3D
var sky_material: ShaderMaterial
var debug_sun_line: MeshInstance3D
var debug_moon_line: MeshInstance3D

func _ready() -> void:
	print("🌍 DayNightCycle Initialized")

	if not world_env:
		push_error("❌ DayNightCycle: world_env is not assigned!")
		return

	var new_env := load("res://default_env.tres") as Environment
	if new_env:
		world_env.environment = new_env
	else:
		push_error("❌ Impossible de charger default_env.tres")
		return

	var env: Environment = world_env.environment
	if env == null:
		push_error("❌ world_env.environment is NULL!")
		return

	var sky := env.sky
	if sky == null:
		push_warning("⚠️ Aucun Sky trouvé dans l'Environment.")
		return

	var mat := sky.sky_material
	if mat is ShaderMaterial:
		sky_material = mat as ShaderMaterial
		print("☀️ Sky shader linked successfully.")
	else:
		push_warning("⚠️ Sky présent mais pas de ShaderMaterial assigné.")

	_create_sun()
	_create_moon()
	#_create_debug_lines()

func _process(delta: float) -> void:
	_update_time(delta)
	_update_celestials()
	_update_environment()
	_update_shader()
	_update_ui()

func _update_time(delta: float) -> void:
	time = fmod(time + delta / day_length_seconds, 1.0)

func _update_celestials() -> void:
	var angle_deg := time * 360.0 - 90.0

	var sun_dir := Vector3(
		cos(deg_to_rad(angle_deg)),
		sin(deg_to_rad(angle_deg)),
		0,
	)

	var moon_dir := -sun_dir

	sun_pivot.global_position = sun_dir * ORBIT_RADIUS
	sun_light.global_position = sun_pivot.global_position
	sun_light.look_at(grid_center)

	moon_pivot.global_position = moon_dir * ORBIT_RADIUS
	moon_light.global_position = moon_pivot.global_position
	moon_light.look_at(grid_center)

	sun_light.visible = sun_dir.y > 0.0
	moon_light.visible = moon_dir.y > 0.0

	if debug_sun_line and debug_sun_line.mesh:
		var sun_immediate := debug_sun_line.mesh as ImmediateMesh
		sun_immediate.clear_surfaces()
		sun_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
		sun_immediate.surface_set_color(Color(1, 1, 0))
		sun_immediate.surface_add_vertex(sun_light.global_position)
		sun_immediate.surface_add_vertex(grid_center)
		sun_immediate.surface_end()

	if debug_moon_line and debug_moon_line.mesh:
		var moon_immediate := debug_moon_line.mesh as ImmediateMesh
		moon_immediate.clear_surfaces()
		moon_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
		moon_immediate.surface_set_color(Color(0.8, 0.8, 1))
		moon_immediate.surface_add_vertex(moon_light.global_position)
		moon_immediate.surface_add_vertex(grid_center)
		moon_immediate.surface_end()

func _update_environment() -> void:
	var env := world_env.environment
	var day_light: float = clamp((sin(time * PI * 2.0) * 0.5 + 0.5), 0.0, 1.0)

	env.ambient_light_energy = lerp(0.05, 0.4, day_light)
	env.ambient_light_color = Color(0.07, 0.08, 0.12).lerp(Color(1, 1, 1), day_light)

	env.fog_enabled = true
	var fog_night := Color(0.07, 0.08, 0.12)
	var fog_day := Color(0.55, 0.65, 0.85)
	env.fog_light_color = fog_night.lerp(fog_day, day_light)
	env.fog_light_energy = lerp(0.6, 0.05, day_light)
	env.fog_density = lerp(0.025, 0.01, day_light)

func _update_shader() -> void:
	if not sky_material:
		return

	sky_material.set_shader_parameter("time_of_day", time)
	sky_material.set_shader_parameter("sun_direction", -sun_light.global_transform.basis.z.normalized())
	sky_material.set_shader_parameter("moon_direction", -moon_light.global_transform.basis.z.normalized())

func _update_ui() -> void:
	if Engine.is_editor_hint():
		return

	var moment_label := get_node_or_null("../UI/VBoxContainer/FoldableDayTime/VBoxContainer/HBoxContainerMoment/MomentValue") as Label
	if moment_label:
		moment_label.text = _get_day_phase()

	var time_label := get_node_or_null("../UI/VBoxContainer/FoldableDayTime/VBoxContainer/HBoxContainerTime/TimeValue") as Label
	if time_label:
		time_label.text = _format_time()

func _get_day_phase() -> String:
	var hour := time * 24.0

	if hour < 4.0: return "🌑 Nuit profonde"
	if hour < 6.0: return "🌅 Aube"
	if hour < 6.5: return "🌄 Lever du soleil"
	if hour < 12.0: return "🌤 Matin"
	if hour < 13.0: return "☀️ Midi"
	if hour < 17.0: return "🌞 Après-midi"
	if hour < 19.0: return "🌇 Déclin"
	if hour < 20.0: return "🌆 Crépuscule"
	return "🌌 Nuit"

func _format_time() -> String:
	var minutes := int(time * 1440.0)
	return "%02d:%02d" % [minutes / 60, minutes % 60]

func _create_sun() -> void:
	sun_light = DirectionalLight3D.new()
	sun_light.light_energy = 0.8
	sun_light.shadow_enabled = true
	add_child(sun_light)

func _create_moon() -> void:
	moon_light = DirectionalLight3D.new()
	moon_light.light_energy = 0.25
	moon_light.shadow_enabled = true
	add_child(moon_light)

func _create_debug_lines() -> void:
	debug_sun_line = MeshInstance3D.new()
	debug_sun_line.mesh = ImmediateMesh.new()
	add_child(debug_sun_line)

	debug_moon_line = MeshInstance3D.new()
	debug_moon_line.mesh = ImmediateMesh.new()
	add_child(debug_moon_line)
