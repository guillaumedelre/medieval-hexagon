extends Node

const TWODEE_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/2D.svg")
const POINTS_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/PointMesh.svg")
const GRID_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/Grid.svg")
const ORIGIN_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/CoordinateOrigin.svg")
const SCALE_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/Zoom.svg")
const TOOL_TEXTURE = preload("res://addons/RadialMenu/Demo/icons/Tools.svg")

const TERRAIN_TEXTURE = preload("res://assets/fa/terrain.svg")
const BUILDING_TEXTURE = preload("res://assets/fa/building.svg")
const RESOURCE_TEXTURE = preload("res://assets/fa/trees.svg")

const QUIT_TEXTURE = preload("res://assets/fa/quit.svg")
# Import the Radial Menu
const RadialMenu = preload("res://addons/RadialMenu/RadialMenu.gd")

@onready var radial_menu: RadialMenu = $RadialMenu


func create_submenu(parent_menu):
	# create a new radial menu
	var submenu = RadialMenu.new()
	# copy some important properties from the parent menu
	submenu.circle_coverage = 0.45
	submenu.width = parent_menu.width*1.25
	submenu.default_theme = parent_menu.default_theme
	submenu.show_animation = parent_menu.show_animation
	submenu.animation_speed_factor = parent_menu.animation_speed_factor
	return submenu
		

func create_submenu_grid(parent_menu):
	# create a new radial menu
	var submenu = RadialMenu.new()
	# copy some important properties from the parent menu
	submenu.circle_coverage = 0.45
	submenu.width = parent_menu.width*1.25
	submenu.default_theme = parent_menu.default_theme
	submenu.show_animation = parent_menu.show_animation
	submenu.animation_speed_factor = parent_menu.animation_speed_factor
	submenu.menu_items = [
		{'texture': TERRAIN_TEXTURE, 'title': "Terrrain", 'id': "terrain"},
		{'texture': BUILDING_TEXTURE, 'title': "Terrrain", 'id': "building"},
		{'texture': RESOURCE_TEXTURE, 'title': "Terrrain", 'id': "resource"},
	]
	return submenu
		

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Create a few dummy submenus
	var submenu1 = create_submenu($RadialMenu)
	var submenu2 = create_submenu($RadialMenu)
	var submenu3 = create_submenu_grid($RadialMenu)
	var submenu4 = create_submenu($RadialMenu)
	print(QUIT_TEXTURE)
	#QUIT_TEXTURE.set_size_override(true, Vector2(32, 32))
	# Define the main menu's items
	$RadialMenu.menu_items = [
		{'texture': SCALE_TEXTURE, 'title': "Reset\nscale", 'id': "action7"},
		{'texture': TWODEE_TEXTURE, 'title': "Axis\nSetup", 'id': submenu1}, 
		{'texture': POINTS_TEXTURE, 'title': "Dataset\nSetup", 'id': submenu2},
		{'texture': GRID_TEXTURE, 'title': "Grid\nSetup", 'id': submenu3},
		{'texture': TOOL_TEXTURE, 'title': "Advanced\nTools", 'id': submenu4},
		{'texture': QUIT_TEXTURE, 'title': "Advanced\nTools", 'id': "quit"},
		
		#{'texture': ORIGIN_TEXTURE, 'title': "Back to\norigin", 'id': "action5"},
		#{'texture': SCALE_TEXTURE, 'title': "Reset\nscale", 'id': "action6"},
	]
	
	print("✅ Menu prêt")

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_main_menu"):
		var screen_center: Vector2 = get_viewport().size / 2
		$RadialMenu.open_menu(screen_center)
		get_viewport().set_input_as_handled()


func _on_radial_menu_item_selected(_menu_id: Variant, _position: Variant) -> void:
	match _menu_id:
		"quit":
			get_tree().quit()
		_:
			print(_menu_id)
