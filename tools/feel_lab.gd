extends SceneTree

## 手感对照：同一张"打击"牌，三档震屏参数，逐帧截下来。
##
##   godot --fixed-fps 60 --path . -s res://tools/feel_lab.gd
##
## 为什么要 --fixed-fps：默认的实时同步下，抓一帧要 5-15ms 的显存回读，
## 三次抓帧的间隔就不一样了，对比不成立。定帧之后每帧固定推进 1/60 秒，
## 三个变体的时间轴完全一致，才谈得上"哪档更跟手"。
##
## 输出：shots/feel/<变体>_<帧号>.png + shots/feel/strip_<变体>.png（横向拼条）

const OUT := "res://shots/feel"
const FRAMES := 16
const ZOOM := 3

const VARIANTS: Array = [
	{"name": "1_current", "amount": 2.0, "time": 0.12, "note": "现在用的"},
	{"name": "2_punchy", "amount": 3.6, "time": 0.09, "note": "更短更狠"},
	{"name": "3_soft", "amount": 1.2, "time": 0.18, "note": "更软更长"},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run()


func _run() -> void:
	for v in VARIANTS:
		await _one(v)
	print("FEEL_LAB done -> ", ProjectSettings.globalize_path(OUT))
	quit()


## 一个变体：新开一场战斗 -> 改震屏参数 -> 打一张攻击牌 -> 连抓 FRAMES 帧
func _one(v: Dictionary) -> void:
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	var battle: Node = scene.instantiate()
	battle.set("shake_amount", float(v.amount))
	battle.set("shake_time", float(v.time))
	root.add_child(battle)

	# 等 battle._ready 里那串 await（抽牌、摆敌人）走完。
	# 不能只看"有没有子节点"——发牌是一张张加的，第一张出现时后面还没进容器，
	# 那种半成品手牌里可能一张攻击牌都没有。等它稳定下来再动手。
	var stable := 0
	var last := -1
	for i in 240:
		await process_frame
		var n: int = battle.hand.get_child_count()
		if n >= 4 and n == last:
			stable += 1
			if stable >= 6:
				break
		else:
			stable = 0
		last = n

	var card: Node = _first_attack_card(battle)
	if card == null:
		push_error("feel_lab: 这一 hand 里没有攻击牌，跳过 " + str(v.name))
		battle.queue_free()
		await process_frame
		return

	var enemy: Node = get_nodes_in_group("enemies")[0]
	var frames: Array[Image] = []
	var trace: Array[Vector2] = []
	battle.call("_on_play_requested", card, [enemy])
	for i in FRAMES:
		await RenderingServer.frame_post_draw
		# 震屏就是把战斗根节点（世界层）挪来挪去，所以直接记录它的位移，
		# 比拿像素做配准稳得多（墙砖是重复纹理，配准会锁错位置）。
		trace.append(battle.position)
		var img := root.get_texture().get_image()
		frames.append(img)
		img.save_png("%s/%s_%02d.png" % [OUT, v.name, i])

	var peak := 0.0
	for p in trace:
		peak = maxf(peak, absf(p.x) + absf(p.y))
	var moving := 0
	for p in trace:
		if absf(p.x) + absf(p.y) > 0.01:
			moving += 1
	print("TRACE %s peak=%.2f moving_frames=%d settled_after_ms=%d" % [
		v.name, peak, moving, moving * 16])
	_strip(frames, String(v.name))
	battle.queue_free()
	await process_frame


func _first_attack_card(battle: Node) -> Node:
	for child in battle.hand.get_children():
		var card = child.get("card")
		if card != null and int(card.type) == 0:   # Card.Type.ATTACK == 0
			return child
	return null


## 横向拼条：一眼看完 16 帧里的位移轨迹
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
