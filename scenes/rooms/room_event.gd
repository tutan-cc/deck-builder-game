extends Control

## P31–P34 的房间场景：宝箱 / 事件 / 商店 共用这一个界面。
## 用当前房间的类型决定显示什么——省掉三个几乎一样的场景。

const CARD_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

const PRICE_BY_RARITY := {
	Card.Rarity.COMMON: 35,
	Card.Rarity.UNCOMMON: 60,
	Card.Rarity.RARE: 90,
}

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var body: Label = $Panel/Margin/VBox/Body
@onready var cards_row: HBoxContainer = $Panel/Margin/VBox/Cards
@onready var leave_button: Button = $Panel/Margin/VBox/Actions/Leave
@onready var menu: CardMenu = $CardMenu

var room: Room
var _done := false
var _removing := false


func _ready() -> void:
	room = _current_room()
	leave_button.pressed.connect(_leave)
	menu.card_selected.connect(_on_card_selected)

	match _type():
		Room.Type.SHOP:
			_open_shop()
		Room.Type.TREASURE:
			_open_treasure()
		_:
			_open_event()


func _current_room() -> Room:
	if RunState.current_room >= 0 and RunState.current_room < RunState.map_rooms.size():
		return RunState.map_rooms[RunState.current_room]
	return null


func _type() -> int:
	return room.type if room else Room.Type.EVENT


func _open_treasure() -> void:
	title_label.text = "宝箱"
	body.text = "一个落满灰的木箱。"
	var open_button := Button.new()
	open_button.text = "打开"
	open_button.add_theme_font_size_override("font_size", 12)
	open_button.pressed.connect(func() -> void:
		if _done: return
		_done = true
		var gold := randi_range(15, 30)
		RunState.add_gold(gold)
		body.text = "拿到 %d 金币。" % gold
		Sfx.play("axe")
		open_button.disabled = true)
	$Panel/Margin/VBox/Actions.add_child(open_button)


func _open_event() -> void:
	title_label.text = "事件"
	body.text = "路边有人留下一袋钱，也可能是个陷阱。"
	var grab := Button.new()
	grab.text = "拿走"
	grab.add_theme_font_size_override("font_size", 12)
	grab.pressed.connect(func() -> void:
		if _done: return
		_done = true
		# 事件有代价：要么拿钱，要么掉血
		if randf() < 0.6:
			var gold := randi_range(12, 22)
			RunState.add_gold(gold)
			body.text = "是金币：+%d。" % gold
		else:
			var max_hp: int = RunState.character.max_health if RunState.character else 35
			var now: int = max_hp if RunState.current_health < 0 else RunState.current_health
			RunState.current_health = maxi(1, now - 5)
			body.text = "是陷阱：-5 生命。"
		grab.disabled = true)
	$Panel/Margin/VBox/Actions.add_child(grab)


func _open_shop() -> void:
	title_label.text = "商店"
	body.text = "金币 %d" % RunState.gold

	var picks := RewardPool.draw(3)
	for card in picks:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)

		var card_ui: CardUI = CARD_SCENE.instantiate()
		card_ui.card = card
		card_ui.interactive = false
		column.add_child(card_ui)

		var price: int = PRICE_BY_RARITY.get(card.rarity, 40)
		var buy := Button.new()
		buy.text = "◆ %d" % price
		buy.add_theme_font_size_override("font_size", 12)
		buy.pressed.connect(_buy.bind(card, price, buy))
		column.add_child(buy)

		cards_row.add_child(column)

	_add_remove_service()
	_add_relic_offer()


## 商店服务：花钱移除一张卡（卡组污染的唯一解法）
func _add_remove_service() -> void:
	var remove := Button.new()
	remove.text = "移除一张卡 ◆50"
	remove.add_theme_font_size_override("font_size", 12)
	remove.pressed.connect(func() -> void:
		if RunState.gold < 50:
			body.text = "金币不够（移除要 50）"
			return
		_removing = true
		menu.open(RunState.deck, "选择要移除的卡", true))
	$Panel/Margin/VBox/Actions.add_child(remove)


## 商店服务：卖一个遗物
func _add_relic_offer() -> void:
	var relic := RelicLibrary.random_reward()
	var price := 120
	var buy := Button.new()
	buy.text = "遗物·%s ◆%d" % [relic.title, price]
	buy.add_theme_font_size_override("font_size", 12)
	buy.pressed.connect(func() -> void:
		if not RunState.spend_gold(price):
			body.text = "金币不够（%d / %d）" % [RunState.gold, price]
			return
		RunState.add_relic(relic)
		buy.disabled = true
		buy.text = "已买"
		body.text = "获得遗物 %s" % relic.title
		Sfx.play("axe"))
	$Panel/Margin/VBox/Actions.add_child(buy)


func _on_card_selected(card: Card) -> void:
	if not _removing:
		return
	var index := RunState.deck.find(card)
	if index < 0:
		return
	if not RunState.spend_gold(50):
		_removing = false
		return
	RunState.deck.remove_at(index)
	_removing = false
	body.text = "移除了 %s · 剩 %d 金币" % [card.title, RunState.gold]


func _buy(card: Card, price: int, button: Button) -> void:
	if not RunState.spend_gold(price):
		body.text = "金币不够（%d / %d）" % [RunState.gold, price]
		return
	RunState.add_card(card)
	button.disabled = true
	button.text = "已买"
	body.text = "买下 %s · 剩 %d 金币" % [card.title, RunState.gold]
	Sfx.play("block")


func _leave() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
