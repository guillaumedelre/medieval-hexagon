extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _show_error(scene: Control, msg: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = msg
	scene.add_child(dlg)
	dlg.popup_centered()
