extends Node

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout
	battle.help_panel.visible = true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT %d" % img.save_png("res://shots/s_help.png"))
	get_tree().quit()
