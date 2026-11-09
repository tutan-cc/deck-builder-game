extends Node

func _ready() -> void:
	RunState.reset()
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	print("SHOT %d" % get_viewport().get_texture().get_image().save_png("res://shots/s_menu.png"))
	var sel: Control = load("res://scenes/ui/character_selector.tscn").instantiate()
	add_child(sel)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	print("SHOT %d" % get_viewport().get_texture().get_image().save_png("res://shots/s_select.png"))
	get_tree().quit()
