extends Control
class_name LayerSelector

signal layer_changed(layer_name: String)

func _on_TerrainButton_pressed() -> void:
	emit_signal("layer_changed", "terrain")

func _on_BuildingButton_pressed() -> void:
	emit_signal("layer_changed", "building")

func _on_ResourceButton_pressed() -> void:
	emit_signal("layer_changed", "resource")
