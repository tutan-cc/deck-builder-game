extends Node

## 瞄准时的截图自检：单目标卡拖到敌人身上，确认弧线与箭头都出现。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout

	var aim: CardUI = null
	for child in battle.hand.get_children():
		var card_ui := child as CardUI
		if card_ui and card_ui.card and card_ui.card.is_single_targeted():
			aim = card_ui
			break
	if aim == null:
		aim = battle.hand.get_child(0)

	var enemies := get_tree().get_nodes_in_group("enemies")
	var target: Node2D = enemies[0]
	aim.debug_mouse = target.global_position
	aim.state_machine.transition_to(aim.state_machine.states[CardState.State.DRAGGING])
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame

	var selector: Node = get_tree().get_first_node_in_group("card_target_selector")
	var arrow: Sprite2D = selector.get_node_or_null("Arrow") if selector else null
	print("T aim: state=%s arrow_visible=%s target_scaled=%s" % [
		aim.state_machine.current_state_name(),
		arrow.visible if arrow else "no-selector",
		(target as Node2D).get_node("Icon").scale])

	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	var img := get_viewport().get_texture().get_image()
	print("SHOT aim err=%d" % img.save_png("res://shots/r11_aim.png"))
	get_tree().quit()
