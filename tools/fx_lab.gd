extends SceneTree

## 卡牌特效预览：在真战斗画面上，按游戏里的实际缩放，把候选特效逐帧截下来。
##
##   godot --fixed-fps 60 --path . -s res://tools/fx_lab.gd
##
## 为什么要这个：pixelfx 的 canvas 是 320×180 级的，本工程视口只有 256×144，
## 纸上算出来的 0.5 倍好不好看没用 —— 必须压到真实背景上看。
## 另外还要筛掉 meta.actor 的效果：那些会自己画一个"原装小人"，
## 贴在玩家身上就是两个人在打架（第一版 hit-flash / shield-block 就是这么翻车的）。
##
## 输出：shots/fx/<名字>_<帧号>.png + shots/fx/strip_<名字>.png

const OUT := "res://shots/fx"
const FRAMES := 12
const ZOOM := 3

## 注意：`-s` 传进来的脚本是在 autoload 注册之前编译的，所以这里不能写 `Juice.xxx`
## （编译期会报 Identifier not found）。要用就直接 preload 节点脚本自己建。
const PIXEL_FX := preload("res://addons/pixelfx/nodes/pixel_fx_2d.gd")

## 候选：攻击
const ATTACK_CANDIDATES: Array = [
	{"name": "m_fight_win", "effect": "holy/sunburst", "scale": 0.5, "duration": 1.0, "on_player": true},
	{"name": "m_gold", "effect": "ui/coin-collect", "scale": 0.5, "on_player": true},
	{"name": "m_reward", "effect": "pickups/collect-burst", "scale": 0.5, "on_player": true},
	{"name": "m_death", "effect": "ui/heart-lost", "scale": 0.5, "on_player": true},
	{"name": "m_chest", "effect": "pickups/chest-open", "scale": 0.4, "on_player": false},
	{"name": "m_spawn", "effect": "spawn/spawn-portal", "scale": 0.35, "on_player": false},
]

## 候选：防御
const BLOCK_CANDIDATES: Array = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# 关掉命中定格：它按真实时间放开，而这里抓一帧就要几十毫秒，
	# 录出来会冻在半路，看不出特效本身长什么样。（游戏里照常开）
	var juice := root.get_node_or_null("Juice")
	if juice:
		juice.set("hit_stop_enabled", false)
	_run()


func _run() -> void:
	# 只录候选特效压在真背景上的样子（"现在播了什么"那两步已经验过了）
	for c in ATTACK_CANDIDATES:
		await _preview(c, bool(c.get("on_player", false)))
	for c in BLOCK_CANDIDATES:
		await _preview(c, true)
	print("FX_LAB done -> ", ProjectSettings.globalize_path(OUT))
	quit()


## 开一场战斗，等手牌稳定
func _battle() -> Node:
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	var b: Node = scene.instantiate()
	root.add_child(b)
	var stable := 0
	var last := -1
	for i in 240:
		await process_frame
		var n: int = b.hand.get_child_count()
		if n >= 4 and n == last:
			stable += 1
			if stable >= 6:
				break
		else:
			stable = 0
		last = n
	return b


## 录"现在这张牌打出去的样子"
func _current(name: String, attack: bool) -> void:
	var b := await _battle()
	var card: Node = _card(b, attack)
	if card == null:
		push_warning("fx_lab: 没有可用的 %s 牌" % ("攻击" if attack else "防御"))
	else:
		var targets: Array = []
		if attack:
			targets.append(get_nodes_in_group("enemies")[0])
		await _capture(name, func() -> void: b.call("_on_play_requested", card, targets))
	b.queue_free()
	await process_frame


## 直接把候选特效压在场景上（不动战斗逻辑）
func _preview(c: Dictionary, on_player: bool) -> void:
	var b := await _battle()
	var anchor: Node2D = b.get_node("Player") if on_player else get_nodes_in_group("enemies")[0]
	var pos: Vector2 = anchor.global_position
	await _capture(String(c.name), func() -> void:
		var fx: Node2D = PIXEL_FX.new()
		fx.set("effect", String(c.effect))
		fx.set("mode", PIXEL_FX.Mode.BAKED)
		fx.position = pos
		fx.scale = Vector2.ONE * float(c.get("scale", 0.5))
		fx.z_index = 60
		fx.set("free_when_done", true)
		b.add_child(fx)
		if c.has("duration"):
			var secs := float(c["duration"])
			create_timer(secs).timeout.connect(func() -> void:
				if is_instance_valid(fx):
					fx.queue_free()))
	b.queue_free()
	await process_frame


func _card(b: Node, attack: bool) -> Node:
	for child in b.hand.get_children():
		var card = child.get("card")
		if card != null and (int(card.type) == 0) == attack:
			return child
	return null


## 跑一个动作，然后逐帧抓，最后拼横条
func _capture(name: String, action: Callable) -> void:
	action.call()
	var frames: Array[Image] = []
	for i in FRAMES:
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		frames.append(img)
		img.save_png("%s/%s_%02d.png" % [OUT, name, i])
	_strip(frames, name)


func _strip(frames: Array[Image], name: String) -> void:
	if frames.is_empty():
		return
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var sheet := Image.create_empty(w * ZOOM * frames.size(), h * ZOOM, false, frames[0].get_format())
	sheet.fill(Color(0, 0, 0, 1))
	for i in frames.size():
		var f: Image = frames[i].duplicate()
		f.resize(w * ZOOM, h * ZOOM, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(f, Rect2i(0, 0, w * ZOOM, h * ZOOM), Vector2i(i * w * ZOOM, 0))
	sheet.save_png("%s/strip_%s.png" % [OUT, name])
