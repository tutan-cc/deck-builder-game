class_name PlayerHandler
extends Node

## P12：把"牌堆 + 抽牌 + 弃牌 + 回合开始"从 Battle 里搬出来。
## Battle 只负责战场（敌人、结算目标），牌的事归 handler。
##
## 依赖是**注入**进来的（setup 里传 player / hand / ui_layer），
## 所以这个类不知道 Battle 长什么样，换场景也能用。

signal piles_changed
signal card_played(card_ui: CardUI, targets: Array)

const CARD_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

## 每抽一张之间的间隔（P12 的 Tween 延迟抽牌）
@export var draw_delay := 0.08
@export var hand_size := 5

var draw_pile := CardPile.new()
var discard_pile := CardPile.new()

var player: Player
var hand: HBoxContainer
var ui_layer: CanvasLayer
var discard_point := Vector2(24, 132)


func setup(player_node: Player, hand_node: HBoxContainer, layer: CanvasLayer) -> void:
	player = player_node
	hand = hand_node
	ui_layer = layer
	draw_pile.pile_changed.connect(func(_n: int) -> void: piles_changed.emit())
	discard_pile.pile_changed.connect(func(_n: int) -> void: piles_changed.emit())


func build_deck(cards: Array[Card]) -> void:
	for card in cards:
		draw_pile.add_card(card)
	draw_pile.shuffle()


## 一回合开始：清格挡、回能量、抽满手牌
func start_turn() -> void:
	player.start_turn()
	await draw_cards(hand_size)
	piles_changed.emit()


## 一张一张抽，中间有间隔——玩家能看见牌在补进来，而不是瞬间刷出 5 张
func draw_cards(amount: int) -> void:
	for i in amount:
		if draw_pile.is_empty():
			reshuffle()
		var card := draw_pile.draw_card()
		if card == null:
			return
		_spawn(card)
		if draw_delay > 0.0:
			await get_tree().create_timer(draw_delay).timeout


func _spawn(card: Card) -> void:
	var card_ui: CardUI = CARD_SCENE.instantiate()
	card_ui.card = card
	hand.add_child(card_ui)
	card_ui.play_requested.connect(func(ui: CardUI, targets: Array) -> void:
		card_played.emit(ui, targets))
	# 入场：淡入 + 轻微放大，和 tween 延迟抽牌配套
	card_ui.modulate.a = 0.0
	card_ui.scale = Vector2(0.85, 0.85)
	var tween := card_ui.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_ui, "modulate:a", 1.0, 0.12)
	tween.tween_property(card_ui, "scale", Vector2.ONE, 0.12)


## 抽牌堆空了：弃牌堆洗回抽牌堆（P13 的"洗牌堆"）
func reshuffle() -> void:
	if discard_pile.is_empty():
		return
	for card in discard_pile.cards:
		draw_pile.add_card(card)
	discard_pile.clear()
	draw_pile.shuffle()


## 一张牌进弃牌堆，并播放"飞向弃牌堆"的动画
func discard(card_ui: CardUI) -> void:
	if card_ui == null or card_ui.card == null:
		return
	discard_pile.add_card(card_ui.card)
	_animate_to_discard(card_ui)
	piles_changed.emit()


## 回合结束：手上剩下的全部弃掉
func discard_hand() -> void:
	for child in hand.get_children():
		var card_ui := child as CardUI
		if card_ui:
			discard(card_ui)


## 战斗结束用：不做动画，直接清空（避免结算面板后面还有牌在飞）
func clear_hand_instant() -> void:
	for child in hand.get_children():
		child.queue_free()


func _animate_to_discard(card_ui: CardUI) -> void:
	if ui_layer and card_ui.get_parent() != ui_layer:
		card_ui.reparent(ui_layer)
	var tween := card_ui.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_ui, "global_position", discard_point, 0.18)
	tween.tween_property(card_ui, "scale", Vector2(0.35, 0.35), 0.18)
	tween.tween_property(card_ui, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(card_ui.queue_free)
