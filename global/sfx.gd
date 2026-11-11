extends Node

## P18：全局音效。用几个 AudioStreamPlayer 轮转，避免同时播放时互相打断。
## 作为 autoload 挂上，任何脚本直接 `Sfx.play("slash")`。
##
## 音频是 tools/gen_chip.py 程序化合成的 8-bit（见 docs/音效-2026-11-11.md）。

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
	# UI（全局限量，见 _on_node_added）
	"ui_click": "res://art/audio/ui_click.ogg",
}

var _players: Array[AudioStreamPlayer] = []
var _cache := {}


func _ready() -> void:
	_ensure_players()
	# 全局按键音：任何 Button 被按下都滴一声，不用在每个场景里逐个接。
	# 用 node_added 而不是遍历一次，是因为按钮大多是运行时实例化的（奖励、牌堆预览…）。
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	_wire_buttons(tree.root)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not (node as BaseButton).pressed.is_connected(_on_button_pressed):
		(node as BaseButton).pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play("ui_click", 0.02)


## autoload 比主场景先就绪，所以已经存在的按钮要补一次
func _wire_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_wire_buttons(child)


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
