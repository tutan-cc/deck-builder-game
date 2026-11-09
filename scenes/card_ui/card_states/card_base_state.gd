extends CardState

## base：没被碰的状态。只做两件事——等左键、管悬停。
## 不跑 _process，所以一百张卡挂着也不掉帧。

var _hover_tween: Tween


func enter() -> void:
	set_process(false)
	_scale_to(Vector2.ONE)
	card_ui.z_index = 0


func on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, State.CLICKED)


func on_mouse_entered() -> void:
	card_ui.z_index = 5
	_scale_to(Vector2.ONE * CardUI.HOVER_SCALE)


func on_mouse_exited() -> void:
	card_ui.z_index = 0
	_scale_to(Vector2.ONE)


func _scale_to(target: Vector2) -> void:
	if _hover_tween and _hover_tween.is_valid() and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = card_ui.create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(card_ui, "scale", target, 0.08)
