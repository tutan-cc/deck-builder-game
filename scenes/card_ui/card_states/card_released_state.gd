extends CardState

## released（P10 的目标判断）：松手这一刻决定"这张卡算不算打出去"。
##
## 指定目标的卡：鼠标底下必须有敌人，否则回手牌（这是玩家最常见的取消动作）。
## 其它卡：落在出牌区就算打出。

const RETURN_DELAY := 0.15


func enter() -> void:
	set_process(false)

	if card_ui.card == null:
		_return_home()
		return

	var targets: Array = []
	if card_ui.card.is_single_targeted():
		targets = card_ui.targets_under_mouse()
		if targets.is_empty():
			# 瞄空了：给一次反馈，免得玩家以为卡坏了
			_hint_no_target()
			_return_home()
			return
	elif not card_ui.is_over_play_zone():
		_return_home()
		return

	# 交给 battle 结算：扣能量、执行效果、进弃牌堆
	card_ui.request_play(targets)
	_return_home_neutral()


func _return_home() -> void:
	if card_ui.original_parent == null:
		return
	if card_ui.get_parent() != card_ui.original_parent:
		card_ui.reparent(card_ui.original_parent)
	var last := card_ui.original_parent.get_child_count() - 1
	card_ui.original_parent.move_child(card_ui, mini(card_ui.original_index, last))

	var timer := get_tree().create_timer(RETURN_DELAY, false)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(card_ui):
			transition_requested.emit(self, State.BASE)
	)


## 已经交给 battle 的那条路：不要回手牌，让 battle 决定要不要把这张 UI 收走
func _return_home_neutral() -> void:
	pass

## 告诉玩家"这张卡要选个敌人"，而不是默默把卡弹回去
func _hint_no_target() -> void:
	var label := Label.new()
	label.text = "要选一个敌人"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 120
	var layer := Fx.layer
	layer.add_child(label)
	label.position = card_ui.mouse_position() + Vector2(-40, -30)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 10.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)