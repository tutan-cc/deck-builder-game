extends Node

## 出牌探针：加载战斗 → 从手牌里找一张攻击牌 → 直接调用出牌逻辑
## → 连拍 6 张，覆盖挥砍 / 星芒 / 飘字。
## 光看静态截图没法证明"出牌时有动作"，必须按时间取样。

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/battle/battle.tscn")
	var battle: Node = packed.instantiate()
	add_child(battle)
	for i in 30:
		await get_tree().process_frame

	# 找一张攻击牌（防御牌不会触发挥砍）
	var hand: Node = battle.get_node("UILayer/Hand")
	var card_ui = null
	for child in hand.get_children():
		if child.get("card") and child.card.type == Card.Type.ATTACK:
			card_ui = child
			break
	if card_ui == null:
		push_warning("PROBE 手牌里没有攻击牌")
		get_tree().quit()
		return

	var enemy = get_tree().get_first_node_in_group("enemies")
	print("PROBE play %s -> %s" % [card_ui.card.title, enemy.name if enemy else "null"])
	battle._on_play_requested(card_ui, [enemy] if enemy else [])

	for i in 6:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		print("FRAME %d err=%d" % [i, img.save_png("res://shots/play_%d.png" % i)])
		for k in 3:
			await get_tree().process_frame

	get_tree().quit()
