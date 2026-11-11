extends CardState

## dragging：卡跟着鼠标走。
## 指定目标的卡拖起来就切到 aiming（要画弧线），其它的留在这里。

func enter() -> void:
	card_ui.remember_home()      # 此刻还在手牌里，记下原位（弧线起点 / 松手回位都用它）
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer and card_ui.get_parent() != ui_layer:
		card_ui.reparent(ui_layer)
	card_ui.z_index = 100
	set_process(true)


func post_enter() -> void:
	if card_ui.card and card_ui.card.is_single_targeted():
		request(State.AIMING)


func exit() -> void:
	set_process(false)
	card_ui.z_index = 0


func _process(_delta: float) -> void:
	if Input.is_action_just_released("left_mouse"):
		request(State.RELEASED)
		return
	card_ui.global_position = card_ui.mouse_position() - card_ui.size * 0.5
