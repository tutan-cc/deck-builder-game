extends Node

## 全局飘字。自己持有一个高层 CanvasLayer，所以任何脚本（敌人、玩家、遗物）
## 都能直接 Juice.pop_number()，不用关心当前场景结构。
##
## 坐标是屏幕坐标；本工程没有相机，所以世界坐标直接用。

var layer: CanvasLayer


func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)


func pop_number(world_pos: Vector2, amount: int, color := Color.WHITE, scale := 1.0) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", int(round(11 * scale)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 100
	layer.add_child(label)

	# 按实际字宽居中：原来写死 -3，是给个位数量身定的，两位数会偏右
	label.position = world_pos - Vector2(label.get_minimum_size().x * 0.5, 16)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 11.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tween.chain().tween_callback(label.queue_free)


## 扣血：易伤时更大更红，格挡全吸收时显示灰
func pop_damage(world_pos: Vector2, amount: int, absorbed: int, vulnerable: bool) -> void:
	if amount <= 0 and absorbed > 0:
		pop_number(world_pos, absorbed, Color(0.62, 0.78, 0.95))
		return
	var color := Color(1.0, 0.42, 0.36) if vulnerable else Color(1.0, 0.92, 0.88)
	var size := 1.45 if vulnerable else 1.0
	pop_number(world_pos, amount, color, size)


## 加格挡
func pop_block(world_pos: Vector2, amount: int) -> void:
	pop_number(world_pos, amount, Color(0.62, 0.80, 1.0))


## 播一次性特效帧条（斩击弧 / 打击星芒 / 死亡烟雾），播完自动删。
## frame_w 是单帧宽度：帧数由「贴图宽 / frame_w」推出，和 SpriteAnim 同一套规则。
func play_fx(world_pos: Vector2, tex: Texture2D, frame_w := 16, fps := 20.0, opts := {}) -> void:
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = maxi(1, int(tex.get_width() / float(frame_w)))
	spr.vframes = 1
	spr.position = world_pos + (opts.get("offset", Vector2.ZERO) as Vector2)
	spr.scale = Vector2.ONE * float(opts.get("scale", 1.0))
	spr.z_index = 50
	layer.add_child(spr)

	var frames := spr.hframes
	var tw := spr.create_tween()
	for i in frames:
		tw.tween_callback(func() -> void: spr.frame = i)
		tw.tween_interval(1.0 / fps)
	tw.tween_callback(spr.queue_free)


# ---------- pixelfx（addons/pixelfx）：代码画的像素特效，不用出图 ----------

const PIXEL_FX := preload("res://addons/pixelfx/nodes/pixel_fx_2d.gd")


## 播一个 pixelfx 特效（特效 id 见 addons/pixelfx/docs/CATALOG.md）。
##
## parent 决定它跟谁一起动：挂在敌人/玩家的父节点上，震屏时特效跟着一起晃，
## 而且单位一死（queue_free）特效不会跟着消失——它挂在上一层。
##
## 本工程是 256x144，pixelfx 的效果按 320x180 一类画布画，所以默认 0.5 倍：
## 正好 2:1 缩小，最近邻采样下不会糊，也只是精灵的 8px 大小级别。
## opts: scale / z / palette / light / live / duration（循环类特效必须给 duration）
func play_pixel(parent: Node, effect: String, world_pos: Vector2, opts := {}) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var fx: Node2D = PIXEL_FX.new()
	fx.set("effect", effect)
	fx.position = world_pos
	fx.scale = Vector2.ONE * float(opts.get("scale", 0.5))
	fx.set("mode", PIXEL_FX.Mode.LIVE if opts.get("live", false) else PIXEL_FX.Mode.BAKED)
	fx.set("palette_preset", String(opts.get("palette", "")))
	fx.set("light", float(opts.get("light", 1.0)))
	fx.z_index = int(opts.get("z", 45))
	fx.set("free_when_done", true)
	parent.add_child(fx)
	if opts.has("duration"):
		# 循环特效不会自己结束，给它一个上限
		var secs := float(opts["duration"])
		get_tree().create_timer(secs).timeout.connect(func() -> void:
			if is_instance_valid(fx):
				fx.queue_free())
	return fx


## 预烘 pixelfx 的 BAKED 缓存。
##
## BAKED 是「第一次播才烘全部帧」，那一帧会卡住主线程：实测 holy/heal 冷启动
## 40ms、spawn/poof 28ms，烘完每帧只要 0.2ms。所以进场景时先空烘一遍，
## 把卡顿挪到进场景那一下，别卡在第一次击杀/第一次治疗上。
##
## 参数必须和真正播的那次一致（palette/light/seed 都算进烘焙缓存 key），
## 否则预烘的是另一份缓存，该卡还是卡。
func prewarm(parent: Node, effects: Array, opts := {}) -> void:
	for id in effects:
		var o := opts.duplicate()
		o["z"] = -100
		var fx := play_pixel(parent, String(id), Vector2(-1000, -1000), o)
		if fx:
			fx.visible = false
			fx.queue_free.call_deferred()


# ---------- 命中定格 ----------

var _hit_stop_on := false
## 逐帧录制的工具（tools/fx_lab.gd）会关掉它：定格是按真实时间放开的，
## 而抓一帧就要几十毫秒，录出来会"冻在半路"，看不出特效本身的样子。
var hit_stop_enabled := true


## 命中定格（hit-stop）：把世界冻住 real_seconds 秒真实时间，再放开。
##
## 为什么放在 autoload 而不是 battle 里：这个函数改的是 Engine.time_scale，
## 一旦恢复的协程跟着场景一起被释放，整个游戏会永久停在 0.02 倍速。
## Juice 是常驻节点，恢复一定跑得到。
func hit_stop(real_seconds := 0.06, freeze_scale := 0.02) -> void:
	if _hit_stop_on or not hit_stop_enabled:
		return
	_hit_stop_on = true
	var prev := Engine.time_scale
	Engine.time_scale = freeze_scale
	# 第 3 个参数 ignore_time_scale：否则计时器自己也被冻住，永远等不到
	await get_tree().create_timer(real_seconds, true, false, true).timeout
	Engine.time_scale = prev
	_hit_stop_on = false


# ---------- 场景转场 ----------

var _in_transition := false


## 换场景统一走这个：淡出 → 换场景 → 淡入，总共约 0.32s。
##
## ⚠️ 之前用的是 pixelfx 的 transitions/pixel-dissolve，撤掉了。原因不是 bug，是**不搭**：
## 它的画布是 320×180、格子按 20px 设计；压到本工程 256×144（0.8 倍）之后，
## 格子变成 16px 的碎块，铺满屏幕还压住界面文字，看着像花屏而不是过场。
## pixelfx 的转场是按"整屏作画"设计的，和这种 16px 精灵 + 满屏 UI 的界面不合。
##
## 顺带省掉一件事：全屏特效第一次烘要 400–700ms，以前得在主菜单预烘；
## 现在是纯色块 tween，零烘焙、零启动开销。
func fade_transition(scene_path: String, out_s := 0.14, in_s := 0.18) -> void:
	if _in_transition:
		return
	_in_transition = true

	var cover := CanvasLayer.new()
	cover.layer = 150
	add_child(cover)
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 吃点击：过场期间不该还能拖手牌
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_child(rect)

	var out_tw := create_tween()
	out_tw.tween_property(rect, "color:a", 1.0, out_s)
	await out_tw.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	var in_tw := create_tween()
	in_tw.tween_property(rect, "color:a", 0.0, in_s)
	await in_tw.finished
	if is_instance_valid(cover):
		cover.queue_free()
	_in_transition = false



