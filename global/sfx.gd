extends Node

## P18：全局音效。用几个 AudioStreamPlayer 轮转，避免同时播放时互相打断。
## 作为 autoload 挂上，任何脚本直接 `Sfx.play("slash")`。
##
## 音频是 tools/gen_sfx.py 用阿里云 qwen-audio-3.1-tts-next 生成的（见 docs/音效-2026-11-11.md）。

const SOUNDS := {
	# 战斗
	"slash": "res://art/audio/slash.ogg",
	"block": "res://art/audio/block.ogg",
	"damage": "res://art/audio/damage.ogg",
	"enemy_attack": "res://art/audio/enemy_attack.ogg",
	"enemy_block": "res://art/audio/enemy_block.ogg",
	"enemy_die": "res://art/audio/enemy_die.ogg",
	# 流程
	"card_play": "res://art/audio/card_play.ogg",
	"victory": "res://art/audio/victory.ogg",
	"defeat": "res://art/audio/defeat.ogg",
	"coin": "res://art/audio/coin.ogg",
	"axe": "res://art/audio/axe.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _cache := {}


func _ready() -> void:
	_ensure_players()


## 播放器池按需创建：headless 检查脚本、或任何在 _ready 之前就 play() 的情况，
## 原来会直接 _players[0] 越界报错。池子为空时先建再播。
func _ensure_players() -> void:
	if not _players.is_empty():
		return
	for i in 6:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


## pitch_vary：同一段音效重复播时随机微调音高，不然连打三张牌听起来像机关枪。
func play(sound: String, pitch_vary := 0.05) -> void:
	if not SOUNDS.has(sound):
		return
	_ensure_players()
	if not _cache.has(sound):
		_cache[sound] = load(SOUNDS[sound])
	var stream: AudioStream = _cache[sound]
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = 1.0 + randf_range(-pitch_vary, pitch_vary)
			player.play()
			return
	# 全忙：抢第一个（6 个播放器 + 短音效，实际很难走到这里）
	_players[0].stream = stream
	_players[0].pitch_scale = 1.0 + randf_range(-pitch_vary, pitch_vary)
	_players[0].play()
