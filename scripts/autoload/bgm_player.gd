extends Node
## Фоновая киберпанк-музыка (инструментал, без слов).

const BGM_PATH := "res://assets/audio/cyber_ambient.wav"
const VOLUME_DB := -12.0

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BgmStream"
	add_child(_player)
	var stream := load(BGM_PATH)
	if stream == null:
		push_warning("BGM не найден: %s" % BGM_PATH)
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_player.stream = stream
	_player.volume_db = VOLUME_DB
	_player.bus = "Master"
	_player.play()


func set_muted(muted: bool) -> void:
	if _player:
		_player.stream_paused = muted


func set_volume_db(db: float) -> void:
	if _player:
		_player.volume_db = db
