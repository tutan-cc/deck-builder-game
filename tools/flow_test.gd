extends Node

## 端到端流程自检（不切场景）：地图 → 战斗 → 奖励 → 商店 → 营地 的串联。
## 场景切换会销毁测试节点，所以这里逐段实例化并调用，验证的是"数据与界面能拼起来"。

func _ready() -> void:
	# ① 开局 + 地图
	RunState.start_run(Character.warrior())
	var rooms_before := RunState.map_rooms.size()
	var available := RunState.available_rooms()
	print("T map: rooms=%d available=%s depth=%d" % [rooms_before, str(available), RunState.depth])

	# ② 进一间战斗房，用它的遭遇战
	var battle_room := -1
	for i in RunState.map_rooms.size():
		if RunState.map_rooms[i].type == Room.Type.BATTLE:
			battle_room = i
			break
	RunState.current_room = battle_room
	RunState.depth = RunState.map_rooms[battle_room].row + 1

	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(0.9).timeout
	print("T battle: enemies=%d encounter=%s depth=%d" % [
		get_tree().get_nodes_in_group("enemies").size(), RunState.current_encounter.id, RunState.depth])

	# ③ 打赢 → 奖励 → 选卡（金币要在开打前记，否则读到的是加过之后的）
	var deck_before := RunState.deck.size()
	var gold_before := RunState.gold
	for e in get_tree().get_nodes_in_group("enemies"):
		e.stats.take_damage(999)
	await get_tree().create_timer(0.8).timeout
	var first: CardUI = battle.rewards.row.get_child(0)
	battle.rewards._on_card_input(_click(), first.card, first)
	await get_tree().create_timer(0.5).timeout
	print("T victory: deck %d -> %d, gold %d -> %d, panel=%s" % [
		deck_before, RunState.deck.size(), gold_before, RunState.gold, battle.over_panel.visible])
	battle.queue_free()
	await get_tree().process_frame

	# ④ 商店：买一张卡，金币减少、卡组增加
	var shop_room := Room.new()
	shop_room.type = Room.Type.SHOP
	RunState.map_rooms.append(shop_room)
	RunState.current_room = RunState.map_rooms.size() - 1
	RunState.gold = 100
	var shop: Control = load("res://scenes/rooms/room_event.tscn").instantiate()
	add_child(shop)
	await get_tree().create_timer(0.3).timeout
	var deck_at_shop := RunState.deck.size()
	var column: VBoxContainer = shop.cards_row.get_child(0)
	var buy_button: Button = column.get_child(1)
	buy_button.pressed.emit()
	await get_tree().create_timer(0.2).timeout
	print("T shop: deck %d -> %d, gold=100 -> %d" % [deck_at_shop, RunState.deck.size(), RunState.gold])
	shop.queue_free()
	await get_tree().process_frame

	# ⑤ 营地：回血 + 升级
	RunState.current_health = 10
	var camp: Control = load("res://scenes/campfire/campfire.tscn").instantiate()
	add_child(camp)
	await get_tree().create_timer(0.2).timeout
	camp._rest()
	await get_tree().process_frame
	var before_upgrade: String = RunState.deck[0].title
	camp._on_card_selected(RunState.deck[0])
	await get_tree().process_frame
	print("T campfire: hp=10 -> %d, %s -> %s" % [RunState.current_health, before_upgrade, RunState.deck[0].title])

	get_tree().quit()


func _click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event
