class_name CardState
extends Node

## 卡牌状态基类。每个状态是一个子节点，只做三件事：
## 1. 进来时收拾自己的样子（enter）
## 2. 收到输入/每帧时判断要不要换状态（on_gui_input / _process）
## 3. 走的时候把借的东西还回去（exit）

enum State { BASE, CLICKED, DRAGGING, RELEASED, AIMING }

signal transition_requested(from: CardState, to: State)

@export var state: State

var card_ui: CardUI


func enter() -> void:
	pass


func exit() -> void:
	pass


func post_enter() -> void:
	pass


func on_gui_input(_event: InputEvent) -> void:
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass
