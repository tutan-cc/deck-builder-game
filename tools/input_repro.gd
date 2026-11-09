extends Node

## 用 Input.parse_input_event 走真实输入（它会更新 Input 的鼠标状态，
## 所以 get_global_mouse_position / is_action_just_released 都跟真手一样）。
## 窗口 1280×720、视口 256×144 → 坐标乘 5。

const SCALE := 1.0   # parse_input_event 走的是视口坐标，不用乘


func _ready() -> void:
	RunState.start_run(Character.warrior())
	RunState.current_room = -1
	var battle: Battle = load("res://scenes/battle/battle.tscn").instantiate()
	add_child(battle)
	await get_tree().create_timer(1.2).timeout

	var card: CardUI = null
	for child in battle.hand.get_children():
		var c := child as CardUI
		if c and c.card and c.card.type == Card.Type.ATTACK:
			card = c
			break
	if card == null:
		print("T 没有攻击牌")
		get_tree().quit()
		return

	var enemy: Node2D = get_tree().get_nodes_in_group("enemies")[0]
	var from: Vector2 = card.get_global_rect().get_center()
	var to: Vector2 = enemy.global_position
	print("T from=%s to=%s" % [str(from), str(to)])

	_move(from)
	await get_tree().process_frame
	_button(true, from)
	await get_tree().process_frame
	await get_tree().process_frame
	print("T press -> state=%s" % card.state_machine.current_state_name())

	for i in range(1, 8):
		_move(from.lerp(to, float(i) / 7.0))
		await get_tree().process_frame
	print("T move -> state=%s mouse=%s targets=%d" % [
		card.state_machine.current_state_name(),
		str(card.mouse_position()), card.targets_under_mouse().size()])

	_button(false, to)
	await get_tree().create_timer(0.4).timeout
	print("T release -> state=%s energy=%d hand=%d discard=%d" % [
		card.state_machine.current_state_name(),
		battle.player.stats.energy, battle.hand.get_child_count(),
		battle.handler.discard_pile.size()])

	get_tree().quit()


func _move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos * SCALE
	e.global_position = pos * SCALE
	Input.parse_input_event(e)


func _button(down: bool, pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.pressed = down
	e.position = pos * SCALE
	e.global_position = pos * SCALE
	Input.parse_input_event(e)
