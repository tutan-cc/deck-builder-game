class_name CardRewards
extends Control

## P28–P30：战斗奖励——金币 + 三选一。
## 选中的卡直接进 RunState.deck（跨场景），跳过后照常继续。

signal closed

const CARD_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

@onready var gold_label: Label = $Panel/Margin/VBox/Header/Gold
@onready var row: HBoxContainer = $Panel/Margin/VBox/Cards
@onready var skip_button: Button = $Panel/Margin/VBox/Actions/Skip

var _picked := false


func _ready() -> void:
	visible = false
	skip_button.pressed.connect(func() -> void: _finish())


func open(cards: Array, gold: int) -> void:
	_picked = false
	gold_label.text = "◆ +%d" % gold
	for child in row.get_children():
		child.queue_free()

	for card in cards:
		var card_ui: CardUI = CARD_SCENE.instantiate()
		card_ui.card = card
		card_ui.interactive = false
		card_ui.gui_input.connect(_on_card_input.bind(card, card_ui))
		row.add_child(card_ui)

	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)


func _on_card_input(event: InputEvent, card: Card, card_ui: CardUI) -> void:
	if _picked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_picked = true
		RunState.add_card(card)
		RunState.battles_won += 1
		# 选中的那张高亮一下再收走，给"我选了它"一个视觉确认
		var tween := create_tween()
		tween.tween_property(card_ui, "modulate", Color(1.6, 1.5, 1.1), 0.1)
		tween.tween_interval(0.12)
		tween.tween_callback(_finish)


func _finish() -> void:
	if not _picked:
		RunState.battles_won += 1
		_picked = true
	visible = false
	closed.emit()


func card_count() -> int:
	return row.get_child_count()
