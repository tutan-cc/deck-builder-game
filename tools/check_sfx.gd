extends SceneTree

## 校验音效：资源能 load、时长对、Sfx.SOUNDS 里的键真能播。
##
##   godot --headless --path . -s res://tools/check_sfx.gd
##
## 为什么要有这个：音频是脚本批量生成的（tools/gen_sfx.py），
## 生成/裁剪/转码/改名任何一步出问题，进游戏才发现就太晚了。
##
## 播放检查必须等到下一帧：在 _initialize() 里 autoload 还没进场景树，
## 直接 play() 会报 "Playback can only happen when a node is inside the scene tree"。

const SOUNDS := {
	"slash": 0.32, "block": 0.26, "damage": 0.26, "enemy_attack": 0.30,
	"enemy_block": 0.24, "enemy_die": 0.50, "card_play": 0.16,
	"victory": 1.50, "defeat": 1.50, "coin": 0.23, "axe": 0.32,
	"ui_click": 0.07,
}

var _bad := 0


func _initialize() -> void:
	for name in SOUNDS:
		var path := "res://art/audio/%s.ogg" % name
		if not ResourceLoader.exists(path):
			print("MISSING  %-14s %s" % [name, path])
			_bad += 1
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			print("FAIL     %-14s 加载不出来" % name)
			_bad += 1
			continue
		var length: float = stream.get_length()
		var expect: float = SOUNDS[name]
		var ok := absf(length - expect) <= 0.08
		# 不读 mix_rate：AudioStreamOggVorbis 上没有这个属性，取错会让脚本中途抛错
		print("%s  %-14s %5.2fs (expect %.2fs)" % [
			"OK      " if ok else "LENGTH? ", name, length, expect])
		if not ok:
			_bad += 1

	if _bad > 0:
		print("SFX_CHECK failed（资源层）")
		quit(1)
		return
	# 资源都对，下一帧再验播放路径（那时 autoload 已在树里）
	process_frame.connect(_play_test, CONNECT_ONE_SHOT)


func _play_test() -> void:
	var sfx := root.get_node_or_null("Sfx")
	if sfx == null:
		print("PLAY    failed：找不到 /root/Sfx")
		quit(1)
		return
	for name in SOUNDS:
		sfx.call("play", name)
	var loaded := 0
	for player in sfx.get("_players"):
		if (player as AudioStreamPlayer).stream != null:
			loaded += 1
	print("PLAY    %d 个播放器装载了音源" % loaded)
	if loaded == 0:
		_bad += 1

	# 全局按键音：新建一个 Button 丢进树里，Sfx 应该靠 node_added 自动接上 pressed
	var btn := Button.new()
	root.add_child(btn)
	var wired: bool = btn.pressed.is_connected(Callable(sfx, "_on_button_pressed"))
	print("BUTTON  %s" % ("已自动接上 ui_click" if wired else "没接上（全局按键音不会响）"))
	if not wired:
		_bad += 1
	btn.queue_free()

	print("SFX_CHECK %s (%d/%d)" % ["failed" if _bad else "passed", SOUNDS.size() - _bad, SOUNDS.size()])
	quit(1 if _bad else 0)
