extends Node

## 验证瞄准容差：点敌人中心、血量数字、意图位置分别算不算命中。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(1.0).timeout

	var card: CardUI = null
	for child in battle.hand.get_children():
		var c := child as CardUI
		if c and c.card:
			card = c
			break
	var enemy: Node2D = get_tree().get_nodes_in_group("enemies")[0]
	var base := enemy.global_position
	var probes := {
		"中心": base,
		"血量数字": base + Vector2(0, -20),
		"意图": base + Vector2(0, -34),
		"斜下": base + Vector2(10, 10),
		"偏左15": base + Vector2(-15, 0),
		"远处": base + Vector2(0, -50),
	}
	for key in probes.keys():
		card.debug_mouse = probes[key]
		print("T %s -> targets=%d" % [key, card.targets_under_mouse().size()])
	get_tree().quit()
