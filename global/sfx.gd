extends Node

## P18：全局音效。用几个 AudioStreamPlayer 轮转，避免同时播放时互相打断。
## 作为 autoload 挂上，任何脚本直接 `Sfx.play("slash")`。

const SOUNDS := {
	"slash": "res://art/slash.ogg",
	"block": "res://art/block.ogg",
	"enemy_attack": "res://art/enemy_attack.ogg",
	"enemy_block": "res://art/enemy_block.ogg",
	"axe": "res://art/axe.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _cache := {}


func _ready() -> void:
	for i in 5:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func play(sound: String) -> void:
	if not SOUNDS.has(sound):
		return
	if not _cache.has(sound):
		_cache[sound] = load(SOUNDS[sound])
	var stream: AudioStream = _cache[sound]
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	_players[0].stream = stream
	_players[0].play()
