extends Control

## P23：Run 场景是中枢——角色、层数、卡组、遗物都从这里看；
## 点「进入战斗」才切到战斗场景。P24/P25 把卡组视图挂在这里。

@onready var char_label: Label = $Box/Character
@onready var depth_label: Label = $Box/Depth
@onready var relic_label: Label = $Box/Relics
@onready var deck_button: Button = $Box/Buttons/Deck
@onready var enter_button: Button = $Box/Buttons/Enter
@onready var card_menu: CardMenu = $CardMenu


func _ready() -> void:
	if RunState.character == null:
		RunState.reset()
	deck_button.pressed.connect(func() -> void:
		card_menu.open(RunState.deck, "卡组"))
	enter_button.pressed.connect(_enter_battle)
	_refresh()


func _refresh() -> void:
	char_label.text = "%s  ·  HP %d  ·  能量 %d" % [
		RunState.character_title(),
		RunState.character.max_health,
		RunState.character.max_energy]
	depth_label.text = "第 %d 层 · ◆ %d" % [RunState.depth, RunState.gold]
	var titles := RunState.relic_titles()
	relic_label.text = "遗物：" + ("、".join(titles) if not titles.is_empty() else "无")
	deck_button.text = "卡组 %d" % RunState.deck.size()


func _enter_battle() -> void:
	# P31：先进地图，由地图决定打哪个房间
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
