extends Node

## 攻击动画探针：加载战斗 → 强制结束回合让敌人出手 → 连拍 6 张。
## 静态截图拍不到攻击帧，必须按时间取样才能证明动画真的播了。

const N := 6


func _ready() -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var battle: Node = packed.instantiate()
	add_child(battle)
	for i in 30:
		await get_tree().process_frame

	print("PROBE end_turn")
	battle.end_turn()

	for i in N:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		print("FRAME %d err=%d" % [i, img.save_png("res://shots/attack_%d.png" % i)])
		# 每张间隔约 3 帧（≈0.05s），覆盖整个扑击窗口
		for k in 3:
			await get_tree().process_frame

	# 等一段再拍一张：验证攻击帧播完会回到待机姿势，而不是僵住
	var t := 0.0
	while t < 1.2:
		await get_tree().process_frame
		t += get_process_delta_time()
	await RenderingServer.frame_post_draw
	var late := get_viewport().get_texture().get_image()
	print("LATE err=%d" % late.save_png("res://shots/attack_late.png"))

	get_tree().quit()
