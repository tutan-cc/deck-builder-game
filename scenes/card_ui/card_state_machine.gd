class_name CardStateMachine
extends Node

## 状态机本体：只管三件事——谁现在是当前状态、切过去、把输入转给当前状态。
## 它不关心"为什么"要切，那是各个状态自己的判断。

signal state_changed(state_name: String)

const NAMES := {
	CardState.State.BASE: "base",
	CardState.State.CLICKED: "clicked",
	CardState.State.DRAGGING: "dragging",
	CardState.State.RELEASED: "released",
	CardState.State.AIMING: "aiming",
}

var current_state: CardState
var states := {}


func init(card: CardUI) -> void:
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			child.card_ui = card
			child.transition_requested.connect(_on_transition_requested)
			child.set_process(false)
	transition_to(states.get(CardState.State.BASE))


## 只读卡（卡组视图）用：把所有状态的处理关掉。
## 不关的话 _process 会跑，但 card_ui 是空的，每帧报错。
func disable_all() -> void:
	for child in get_children():
		if child is CardState:
			child.set_process(false)


func current_state_name() -> String:
	return NAMES.get(current_state.state, "?") if current_state else "?"


func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)


func on_mouse_entered() -> void:
	if current_state:
		current_state.on_mouse_entered()


func on_mouse_exited() -> void:
	if current_state:
		current_state.on_mouse_exited()


func _on_transition_requested(from: CardState, to: CardState.State) -> void:
	# 迟到的请求直接丢掉：避免"已经松手了，延迟的拖动请求又把卡拽走"
	if from != current_state:
		return
	var next: CardState = states.get(to)
	if next:
		transition_to(next)


func transition_to(next: CardState) -> void:
	if next == null or next == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = next
	next.enter()
	next.post_enter()
	state_changed.emit(NAMES.get(next.state, "?"))
