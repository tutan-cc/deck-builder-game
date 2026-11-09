extends Control

## P21：主菜单。只负责两件事——进角色选择、退出。

@onready var start_button: Button = $Box/Start
@onready var quit_button: Button = $Box/Quit


func _ready() -> void:
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/character_selector.tscn"))
	quit_button.pressed.connect(func() -> void:
		get_tree().quit())
