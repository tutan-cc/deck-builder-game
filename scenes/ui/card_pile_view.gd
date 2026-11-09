class_name CardPileView
extends Control

## P13：点牌堆看里面有什么。UI 只读数据，不改牌堆。

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/List


func _ready() -> void:
	visible = false


func show_pile(title: String, cards: Array) -> void:
	title_label.text = "%s  %d 张" % [title, cards.size()]
	for child in list.get_children():
		child.queue_free()
	if cards.is_empty():
		_add_line("（空）")
	else:
		for card in cards:
			_add_line("· %s" % card.title)
	visible = true


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	list.add_child(label)


func hide_view() -> void:
	visible = false


func toggle(title: String, cards: Array) -> void:
	if visible:
		hide_view()
	else:
		show_pile(title, cards)
