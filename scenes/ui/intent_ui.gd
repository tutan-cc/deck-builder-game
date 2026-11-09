class_name IntentUI
extends Control

## P16：敌人头顶的意图。玩家要能"先看到它要干什么"，再决定打谁。

@onready var label: Label = $Label

const ATTACK_COLOR := Color(1.0, 0.45, 0.45)
const BLOCK_COLOR := Color(0.6, 0.8, 1.0)
const BUFF_COLOR := Color(0.95, 0.85, 0.5)


func clear() -> void:
	label.text = ""


func show_action(action: EnemyAction) -> void:
	if action == null:
		clear()
		return
	label.text = action.label()
	match action.type:
		EnemyAction.Type.ATTACK:
			label.modulate = ATTACK_COLOR
		EnemyAction.Type.BLOCK:
			label.modulate = BLOCK_COLOR
		_:
			label.modulate = BUFF_COLOR
