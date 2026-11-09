class_name BattleOverPanel
extends Control

## P19：胜利 / 失败面板。除了显示结果，还负责暂停输入。

signal restart_requested
signal continue_requested

@onready var dim: ColorRect = $Dim
@onready var title: Label = $Box/Title
@onready var subtitle: Label = $Box/Subtitle
@onready var restart_button: Button = $Box/Restart

var _won := false


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(func() -> void:
		if _won:
			continue_requested.emit()
		else:
			restart_requested.emit())


func show_result(won: bool, detail := "") -> void:
	visible = true
	_won = won
	title.text = "Victorious!" if won else "Defeated..."
	title.add_theme_color_override("font_color",
		Color(0.98, 0.85, 0.45) if won else Color(0.95, 0.4, 0.4))
	subtitle.text = detail
	restart_button.text = "继续前进" if won else "再来一局"
	# 面板淡入，比"啪一下出现"舒服
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
