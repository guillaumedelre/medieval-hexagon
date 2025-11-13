extends Node3D

@onready var tile_browser: Control = $UI/TileBrowser
@onready var terrain: Node = self

func _ready() -> void:
	if tile_browser and terrain.has_method("_on_model_selected"):
		if not tile_browser.is_connected("model_selected", Callable(terrain, "_on_model_selected")):
			tile_browser.model_selected.connect(Callable(terrain, "_on_model_selected"))
			print("✅ MapEditor prêt — signal du TileBrowser connecté.")
	else:
		push_warning("⚠️ Impossible de connecter TileBrowser → _on_model_selected().")
