extends Node

## 死亡烟雾探针：直接把一个敌人打死，连拍 5 张看烟雾有没有冒出来。

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
	print("PROBE kill hp=%d" % e.stats.health)
	e.take_damage(9999)

	for i in 5:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		print("FRAME %d err=%d" % [i, img.save_png("res://shots/death_%d.png" % i)])
		for k in 3:
			await get_tree().process_frame

	get_tree().quit()
