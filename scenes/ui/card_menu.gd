class_name CardMenu
extends Control

## P24：卡组视图。滚动容器 + 网格布局，卡多了一屏放不下就竖着滚。
## P25：里面的卡是**只读**的（interactive = false），但悬停照样出提示。
## P39+：加"可选"模式——营地升级、商店删卡都要"点一张卡的界面"。

signal card_selected(card: Card)

const CARD_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/Margin/VBox/Scroll/Grid
@onready var title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var close_button: Button = $Panel/Margin/VBox/Header/Close

var _selectable := false


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)


func open(cards: Array, title := "卡组", selectable := false) -> void:
	_selectable = selectable
	title_label.text = "%s  %d 张%s" % [title, cards.size(), "（点一张）" if selectable else ""]
	for child in grid.get_children():
		child.queue_free()

	for card in cards:
		var card_ui: CardUI = CARD_SCENE.instantiate()
		card_ui.card = card
		card_ui.interactive = false      # 只读：不能拖、不能打
		if selectable:
			card_ui.gui_input.connect(_on_card_input.bind(card))
		grid.add_child(card_ui)

	visible = true
	# 滑入：面板从略小放大 + 整体淡入
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.16)


func _on_card_input(event: InputEvent, card: Card) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _selectable:
		return
	close()
	card_selected.emit(card)


func close() -> void:
	visible = false


func card_count() -> int:
	return grid.get_child_count()
