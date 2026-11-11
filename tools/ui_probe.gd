extends Node

## 一次性探针：把 StatsUI / IntentUI 各种状态摆出来截图。
## 战斗里不一定同时出现"有盾 + 有状态 + 三种意图"，但布局必须每种都撑得住。


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.35, 0.26, 0.20)
	bg.size = Vector2(160, 80)
	add_child(bg)

	var s := Stats.new()
	s.max_health = 35
	s.health = 21
	s.block = 7
	s.add_status(Stats.VULNERABLE, 2)
	s.add_status(Stats.STRENGTH, 1)

	var stats_ui: Control = load("res://scenes/ui/stats_ui.tscn").instantiate()
	stats_ui.position = Vector2(6, 6)
	add_child(stats_ui)
	stats_ui.bind(s)

	# 三种意图横排
	var x := 6.0
	var types := [EnemyAction.Type.ATTACK, EnemyAction.Type.BLOCK, EnemyAction.Type.BUFF]
	for t in types:
		var a := EnemyAction.new()
		a.type = t
		a.value = 6
		var iu: Control = load("res://scenes/ui/intent_ui.tscn").instantiate()
		iu.position = Vector2(x, 34)
		add_child(iu)
		iu.show_action(a)
		x += 30.0

	# 空格挡（block = 0）时盾徽必须消失
	var s2 := Stats.new()
	s2.max_health = 35
	s2.health = 30
	var stats_ui2: Control = load("res://scenes/ui/stats_ui.tscn").instantiate()
	stats_ui2.position = Vector2(6, 50)
	add_child(stats_ui2)
	stats_ui2.bind(s2)

	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("PROBE err=%d" % img.save_png("res://shots/ui_probe.png"))
	get_tree().quit()
