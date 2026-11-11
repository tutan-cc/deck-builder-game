extends CardState

## clicked：按下了，但还没拖。
## 存在的意义是把"点一下"和"拖出去"分开——没有这个中间态，
## 每次轻点都会触发一次拖动，手感会很脏。

const DRAG_THRESHOLD := 4.0

var _press_position := Vector2.ZERO


func enter() -> void:
	_press_position = card_ui.get_global_mouse_position()
	card_ui.remember_home()   # 此刻还在手牌里，记住位置，松手才放得回去
	card_ui.z_index = 1
	set_process(true)


func exit() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	# 先判松手：按一下立刻放开 = 回到 base，不该被当成拖动
	if Input.is_action_just_released("left_mouse"):
		request(State.BASE)
		return

	if card_ui.get_global_mouse_position().distance_to(_press_position) > DRAG_THRESHOLD:
		request(State.DRAGGING)
