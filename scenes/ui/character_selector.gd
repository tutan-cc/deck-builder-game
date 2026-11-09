extends Control

## P21/P22：角色选择。两个按钮进同一个 ButtonGroup——
## 选了 B 会自动取消 A，不用手写互斥逻辑。

@onready var warrior_button: Button = $Box/Choices/Warrior
@onready var hunter_button: Button = $Box/Choices/Hunter
@onready var info: Label = $Box/Info
@onready var go_button: Button = $Box/Go

var _selected: Character


func _ready() -> void:
	var group := ButtonGroup.new()
	warrior_button.button_group = group
	hunter_button.button_group = group
	warrior_button.toggled.connect(func(on: bool) -> void:
		if on: _select(Character.warrior()))
	hunter_button.toggled.connect(func(on: bool) -> void:
		if on: _select(Character.hunter()))
	go_button.pressed.connect(_start)
	warrior_button.button_pressed = true
	_select(Character.warrior())


func _select(character: Character) -> void:
	_selected = character
	info.text = "%s\n%s\n初始卡组 %d 张" % [
		character.title, character.description, character.starting_deck.size()]


func _start() -> void:
	if _selected == null:
		_selected = Character.warrior()
	RunState.start_run(_selected)
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")
