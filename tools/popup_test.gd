extends Node

## 飘字自检：打一张 Strike，抓一帧看数字有没有出来。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout

	var enemy: Node = get_tree().get_nodes_in_group("enemies")[0]
	var strike: CardUI = null
	for child in battle.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.id == "strike":
			strike = card_ui
			break
	if strike == null:
		strike = battle.hand.get_child(0)

	# 让敌人带易伤，数字应该更大更红
	enemy.add_status(Stats.VULNERABLE, 2)
	battle._on_play_requested(strike, [enemy])
	await get_tree().create_timer(0.12).timeout

	var layer: CanvasLayer = Fx.layer
	print("T fx labels=%d" % layer.get_child_count())
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	var img := get_viewport().get_texture().get_image()
	print("SHOT %d" % img.save_png("res://shots/s_popup.png"))
	get_tree().quit()
