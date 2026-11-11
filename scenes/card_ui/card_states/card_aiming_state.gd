extends CardState

## aiming（P4/P5）：指定目标的卡拖出来之后进入这里。
## 和 dragging 的区别是：它同时在画一条弧线，并持续找"鼠标底下是谁"。

func enter() -> void:
	card_ui.z_index = 100
	var selector := get_tree().get_first_node_in_group("card_target_selector")
	if selector:
		selector.start(card_ui)
	set_process(true)


func exit() -> void:
	set_process(false)
	var selector := get_tree().get_first_node_in_group("card_target_selector")
	if selector:
		selector.stop()


func _process(_delta: float) -> void:
	if Input.is_action_just_released("left_mouse"):
		request(State.RELEASED)
		return
	# 卡仍然跟着鼠标（和 dragging 一样），弧线由 selector 每帧重画
	card_ui.global_position = card_ui.mouse_position() - card_ui.size * 0.5
