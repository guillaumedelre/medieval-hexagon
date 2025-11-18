extends Node3D
class_name DayNightCycle

@export var sun_pivot: Node3D
@export var sun_light: DirectionalLight3D
@export var moon_pivot: Node3D
@export var moon_mesh: MeshInstance3D
@export var world_env: WorldEnvironment
@export var animation_player: AnimationPlayer = get_node_or_null("./AnimationPlayer")
@export var grid_center: Vector3 = Vector3.ZERO
@export var day_length_seconds: float = 1440
@export var debug_light: bool = false
@export var orbit_radius: float = 100.0

var time_speed: float = 1.0
var time: float = 0.0 # 0 = minuit, 0.5 = midi
var moon_light: DirectionalLight3D
var sky_material: ShaderMaterial
var debug_sun_line: MeshInstance3D
var debug_moon_line: MeshInstance3D

func _ready() -> void:
	print("🌍 DayNightCycle Initialized")

	if not world_env:
		push_error("❌ DayNightCycle: world_env is not assigned!")
		return

	if not moon_mesh:
		push_error("❌ MoonMesh: moon_mesh is not assigned!")
		return

	if not animation_player:
		push_error("❌ AnimationPlayer: AnimationPlayer is not assigned!")
		return


	animation_player.speed_scale = time_speed
	animation_player.play("DayNightCycle")
	_create_moon()
	_create_debug_lines()

func _process(delta: float) -> void:
	_update_time(delta)
	_update_celestials()
	_update_environment()
	_update_ui()

func _update_time(_delta: float) -> void:
	time = animation_player.current_animation_position / day_length_seconds

func _update_celestials() -> void:
	var angle_deg := time * 360.0 - 90.0

	var sun_dir := Vector3(
		cos(deg_to_rad(angle_deg)),
		sin(deg_to_rad(angle_deg)),
		0,
	)

	var moon_dir := -sun_dir

	sun_pivot.global_position = sun_dir * orbit_radius
	sun_light.global_position = sun_pivot.global_position
	sun_light.look_at(grid_center)

	moon_pivot.global_position = moon_dir * orbit_radius
	moon_light.global_position = moon_pivot.global_position
	moon_light.look_at(grid_center)

	moon_mesh.visible = moon_dir.y > 0.0

	if debug_light and debug_sun_line and debug_sun_line.mesh:
		var sun_immediate := debug_sun_line.mesh as ImmediateMesh
		sun_immediate.clear_surfaces()
		sun_immediate.surface_begin(Mesh.PRIMITIVE_LINES)
		sun_immediate.surface_set_color(Color(1, 1, 0))
		sun_immediate.surface_add_vertex(sun_light.global_position)
		sun_immediate.surface_add_vertex(grid_center)
		sun_immediate.surface_end()

	if debug_light and debug_moon_line and debug_moon_line.mesh:
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

func _update_ui() -> void:
	if Engine.is_editor_hint():
		return

	var moment_label := get_node_or_null("../UI/VBoxContainer/FoldableDayTime/VBoxContainer/HBoxContainerMoment/MomentValue") as Label
	if moment_label:
		moment_label.text = _get_day_phase()

	var time_label := get_node_or_null("../UI/VBoxContainer/FoldableDayTime/VBoxContainer/HBoxContainerTime/TimeValue") as Label
	if time_label:
		time_label.text = _format_time()

	var speed_label := get_node_or_null("../UI/VBoxContainer/FoldableDayTime/VBoxContainer/HBoxContainerSpeed/SpeedValue") as Label
	if speed_label:
		speed_label.text = str(time_speed)

func _get_day_phase() -> String:
	var time_ratio = animation_player.current_animation_position / day_length_seconds
	var minutes = int(time_ratio * day_length_seconds)
	var hours : float = float(minutes) / 60

	if hours < 5.0: return "🌑 Nuit profonde"
	if hours < 6.0: return "🌅 Aube"
	if hours < 7.0: return "🌄 Lever du soleil"
	if hours < 12.0: return "🌤 Matin"
	if hours < 13.0: return "☀️ Midi"
	if hours < 16.0: return "🌞 Après-midi"
	if hours < 17.0: return "🌇 Soir"
	if hours < 18.0: return "🌆 Crépuscule"
	return "🌌 Nuit"

func _format_time() -> String:
	var time_ratio = animation_player.current_animation_position / day_length_seconds
	var minutes = int(time_ratio * day_length_seconds)
	var hours : float = float(minutes) / 60

	return "%02d:%02d" % [hours, fmod(minutes, 60)]

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


func _on_speed_value_value_changed(value: float) -> void:
	time_speed = value
	animation_player.speed_scale = time_speed
