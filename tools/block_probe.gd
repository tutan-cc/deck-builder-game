extends Node

## 碎盾探针：给敌人加格挡再打，看碎盾特效有没有播。

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var battle: Node = packed.instantiate()
	add_child(battle)
	for i in 30:
		await get_tree().process_frame

	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		print("PROBE 没有敌人")
		get_tree().quit()
		return
	var e = enemies[0]
	e.add_block(10)
	await get_tree().process_frame
	print("PROBE block=%d hp=%d" % [e.stats.block, e.stats.health])
	e.take_damage(4)

	for i in 5:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		print("FRAME %d err=%d" % [i, img.save_png("res://shots/block_%d.png" % i)])
		for k in 2:
			await get_tree().process_frame

	get_tree().quit()
