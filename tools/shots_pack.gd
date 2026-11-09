extends Node

## 补拍一批截图：失败面板 / 暂停 / 格挡 / 遗物 / 抽牌中。
## 跑一次会把 shots/ 下的 s_*.png 都生成好。

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))

	# ① 战斗里打一张 Defend → 格挡数字出现
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout

	var defend: CardUI = _find(battle, "defend")
	if defend:
		battle._on_play_requested(defend, [])
		await get_tree().create_timer(0.4).timeout
	print("T block=%d" % battle.player.stats.block)
	await shot("res://shots/s_block")

	# ② 暂停
	battle._toggle_pause()
	await get_tree().process_frame
	await shot("res://shots/s_pause")
	battle._toggle_pause()
	await get_tree().process_frame

	# ③ 抽牌中（结束回合后立刻抓）
	battle.end_turn()
	await get_tree().create_timer(1.35).timeout
	await shot("res://shots/s_drawing")

	# ④ 失败面板
	battle.player.take_damage(999)
	await get_tree().create_timer(0.6).timeout
	print("T defeat panel=%s" % battle.over_panel.visible)
	await shot("res://shots/s_defeat")
	battle.queue_free()
	await get_tree().process_frame

	# ⑤ 带两个遗物的 Run 中枢
	RunState.reset()
	RunState.add_relic(RelicLibrary.turtle_shell())
	RunState.add_relic(RelicLibrary.thorn_ring())
	RunState.gold = 86
	var run: Control = load("res://scenes/run/run.tscn").instantiate()
	add_child(run)
	await get_tree().create_timer(0.3).timeout
	print("T relics=%s" % str(RunState.relic_titles()))
	await shot("res://shots/s_relics")

	get_tree().quit()


func _find(battle: Battle, id: String) -> CardUI:
	for child in battle.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.id == id:
			return card_ui
	return null


func shot(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT %s err=%d" % [path, img.save_png(path + ".png")])
