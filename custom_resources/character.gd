class_name Character
extends Resource

## P21/P22：一个可选角色。数值和初始卡组都在这里，
## 角色选择界面只负责把这份数据交给 RunState，不认识战斗。

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var art: Texture2D
@export var max_health := 35
@export var max_energy := 3
@export var starting_deck: Array[Card] = []


static func warrior() -> Character:
	var character := Character.new()
	character.id = "warrior"
	character.title = "战士"
	character.description = "35 血 · 3 能量 · 攻守均衡"
	character.art = load("res://art/tile_0130.png")
	character.max_health = 35
	character.max_energy = 3
	for i in 4:
		character.starting_deck.append(CardLibrary.strike())
	for i in 4:
		character.starting_deck.append(CardLibrary.defend())
	character.starting_deck.append(CardLibrary.bash())
	return character


static func hunter() -> Character:
	var character := Character.new()
	character.id = "hunter"
	character.title = "猎手"
	character.description = "28 血 · 4 能量 · 爆发高"
	character.art = load("res://art/tile_0108.png")
	character.max_health = 28
	character.max_energy = 4
	for i in 3:
		character.starting_deck.append(CardLibrary.strike())
	for i: int in 2:
		character.starting_deck.append(CardLibrary.defend())
	character.starting_deck.append(CardLibrary.cleave())
	character.starting_deck.append(CardLibrary.bash())
	return character
