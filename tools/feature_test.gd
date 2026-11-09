extends Node

## P26-P30 自检：顶部栏、稀有度、战斗奖励（金币 + 三选一）。

var battle: Battle


func _ready() -> void:
	RunState.start_run(Character.warrior())
	print("T run: char=%s deck=%d gold=%d" % [
		RunState.character_title(), RunState.deck.size(), RunState.gold])

	# P38：走进地图上第一间战斗房，用它自带的遭遇战
	var battle_room := -1
	for i in RunState.map_rooms.size():
		var r: Room = RunState.map_rooms[i]
		if r.type == Room.Type.BATTLE and r.battle_stats != null:
			battle_room = i
			break
	if battle_room >= 0:
		RunState.current_room = battle_room
		RunState.depth = RunState.map_rooms[battle_room].row + 1
		print("T room_encounter=%s tier=%d count=%d" % [
			RunState.map_rooms[battle_room].battle_stats.id,
			RunState.map_rooms[battle_room].battle_stats.battle_tier,
			RunState.map_rooms[battle_room].battle_stats.enemy_count])

	battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout
	print("T spawned enemies=%d encounter=%s" % [
		get_tree().get_nodes_in_group("enemies").size(),
		RunState.current_encounter.id if RunState.current_encounter else "none"])

	# ① 顶部栏 + 稀有度
	var card0: CardUI = battle.hand.get_child(0)
	print("T topbar: hand=%d draw=%d discard=%d" % [
		battle.hand.get_child_count(),
		battle.handler.draw_pile.size(), battle.handler.discard_pile.size()])
	print("T rarity: %s -> %s" % [card0.card.title, card0.card.rarity])
	await shot("res://shots/p26_topbar")

	# ①.5 P37 遗物触发：每回合格挡 + 受伤减伤
	RunState.add_relic(RelicLibrary.turtle_shell())
	RunState.add_relic(RelicLibrary.thorn_ring())
	battle.player.stats.block = 0
	RunState.turn_start_hooks(battle.player)
	print("T relic block=%d (龟壳每回合 3)" % battle.player.stats.block)
	var hp_before: int = battle.player.stats.health
	battle.player.take_damage(6)
	print("T relic damage: hp %d -> %d (6 伤 - 2 减伤, 再被 3 格挡顶)" % [
		hp_before, battle.player.stats.health])
	print("T relic pool=%d" % RelicLibrary.reward_pool().size())

	# ② 打死敌人 → 奖励弹出
	for e in get_tree().get_nodes_in_group("enemies"):
		e.stats.take_damage(99)
	await get_tree().create_timer(0.7).timeout
	print("T rewards: visible=%s cards=%d gold=%d" % [
		battle.rewards.visible, battle.rewards.card_count(), RunState.gold])
	await shot("res://shots/p28_rewards")

	# ③ 选一张 → 进卡组 → 出结算面板
	var deck_before: int = RunState.deck.size()
	var first_card_ui: CardUI = battle.rewards.row.get_child(0)
	battle.rewards._on_card_input(_click_event(), first_card_ui.card, first_card_ui)
	await get_tree().create_timer(0.6).timeout
	print("T picked: deck %d -> %d, battles_won=%d, over_panel=%s" % [
		deck_before, RunState.deck.size(), RunState.battles_won, battle.over_panel.visible])
	await shot("res://shots/p28_after_pick")

	get_tree().quit()


func _click_event() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(path: String) -> void:
	if not path.ends_with(".png"):
		path += ".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT %s err=%d" % [path, img.save_png(path)])
