extends Node

# Liste des musiques (chemins vers tes fichiers)
var playlist: Array[String] = [
	"res://assets/audio/music/whisper-of-ages-1.mp3",
	"res://assets/audio/music/whisper-of-ages-2.mp3",
	"res://assets/audio/music/whispering-leaves-1.mp3",
	"res://assets/audio/music/whispering-leaves-2.mp3",
	"res://assets/audio/music/frozen-heights-1.mp3",
	"res://assets/audio/music/frozen-heights-2.mp3",
	"res://assets/audio/music/winds-of-the-amber-steppe-1.mp3",
	"res://assets/audio/music/winds-of-the-amber-steppe-2.mp3",
	"res://assets/audio/music/glacial-hush-1.mp3",
	"res://assets/audio/music/glacial-hush-2.mp3",
]

var current_index: int = 0

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	# Ajout du player dans l'arbre
	add_child(player)
	player.bus = "Music"
	player.autoplay = false
	player.finished.connect(_on_track_finished)

	_play_index(current_index)

func _play_index(idx: int) -> void:
	if idx < 0 or idx >= playlist.size():
		return

	current_index = idx

	var stream := load(playlist[idx]) as AudioStream
	if stream == null:
		push_error("Impossible de charger %s" % playlist[idx])
		return

	player.stream = stream
	player.play()

func next_track() -> void:
	current_index = (current_index + 1) % playlist.size()
	_play_index(current_index)

func previous_track() -> void:
	current_index = (current_index - 1 + playlist.size()) % playlist.size()
	_play_index(current_index)

func pause_music() -> void:
	if player.playing:
		player.stop()

func resume_music() -> void:
	if not player.playing:
		player.play()

func _on_track_finished() -> void:
	next_track()
