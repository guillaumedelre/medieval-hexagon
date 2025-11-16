extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func error(scene: Node, msg: String) -> void:
	message(scene, "❌ " + msg)

func warning(scene: Node, msg: String) -> void:
	message(scene, "⚠️ " + msg)

func success(scene: Node, msg: String) -> void:
	message(scene, "✅ " + msg)

func info(scene: Node, msg: String) -> void:
	message(scene, "ℹ️ " + msg)

func message(scene: Node, msg: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = msg
	scene.add_child(dlg)
	dlg.popup_centered()
