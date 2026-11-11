class_name IntentUI
extends Control

## P16：敌人头顶的意图。玩家要能"先看到它要干什么"，再决定打谁。
##
## 图标化：原来攻击显示 "6"、格挡显示 "B5"、增益显示 "▲"，
## 后两个是符号/字母占位。现在换成图标 + 纯数字，一眼扫过去不用解码。

const ICONS := {
	EnemyAction.Type.ATTACK: preload("res://art/ui/intent_attack.png"),
	EnemyAction.Type.BLOCK: preload("res://art/ui/intent_defend.png"),
	EnemyAction.Type.BUFF: preload("res://art/ui/intent_buff.png"),
}

const ATTACK_COLOR := Color(1.0, 0.45, 0.45)
const BLOCK_COLOR := Color(0.6, 0.8, 1.0)
const BUFF_COLOR := Color(0.95, 0.85, 0.5)

@onready var label: Label = $Label
@onready var icon: TextureRect = $Icon


func clear() -> void:
	label.text = ""
	icon.visible = false


func show_action(action: EnemyAction) -> void:
	if action == null:
		clear()
		return
	icon.visible = true
	icon.texture = ICONS.get(action.type, ICONS[EnemyAction.Type.ATTACK])
	match action.type:
		EnemyAction.Type.ATTACK:
			label.text = str(action.value)
			label.modulate = ATTACK_COLOR
		EnemyAction.Type.BLOCK:
			label.text = str(action.value)
			label.modulate = BLOCK_COLOR
		_:
			# 增益没有数值，图标本身就是全部信息
			label.text = ""
			label.modulate = BUFF_COLOR
