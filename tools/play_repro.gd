extends Node

## 复现"伤害牌打不出去"：连打三张，看能量、 affordability 和第四次结算。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout

	print("T turn0: energy=%d/%d hand=%d" % [
		battle.player.stats.energy, battle.player.stats.max_energy,
		battle.hand.get_child_count()])

	var enemy: Node = get_tree().get_nodes_in_group("enemies")[0]
	print("T enemy at %s" % str(enemy.global_position))

	# 连打三张 Strike（模拟真实路径：拖到敌人身上松手）
	for i in 3:
		var card: CardUI = _find_attack(battle)
		if card == null:
			print("T round%d: 没找到可打的攻击牌" % i)
			break
		card.debug_mouse = enemy.global_position
		print("T round%d: card=%s cost=%d energy=%d affordable=%s targets=%d" % [
			i, card.card.title, card.card.cost, battle.player.stats.energy,
			str(card.affordable), card.targets_under_mouse().size()])
		battle._on_play_requested(card, [enemy])
		await get_tree().create_timer(0.35).timeout
		print("T  after%d: energy=%d label=%s hand=%d discard=%d" % [
			i, battle.player.stats.energy, battle.player.energy_label.text, battle.hand.get_child_count(),
			battle.handler.discard_pile.size()])

	# 第三张之后还能不能再打
	var last: CardUI = _find_attack(battle)
	if last:
		print("T last: %s cost=%d energy=%d affordable=%s" % [
			last.card.title, last.card.cost, battle.player.stats.energy, str(last.affordable)])
		battle._on_play_requested(last, [enemy])
		await get_tree().create_timer(0.3).timeout
		print("T final: energy=%d hand=%d" % [battle.player.stats.energy, battle.hand.get_child_count()])
	else:
		print("T last: 手里没有攻击牌")

	get_tree().quit()


func _find_attack(battle: Battle) -> CardUI:
	for child in battle.hand.get_children():
		var c := child as CardUI
		if c and c.card and c.card.type == Card.Type.ATTACK:
			return c
	return null
