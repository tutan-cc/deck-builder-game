class_name CardUI
extends Control

## 一张卡的**界面**。卡的数据在 Card 里，这里只负责画出来 + 收输入 + 悬浮提示。

signal play_requested(card_ui: CardUI, targets: Array)

const HOVER_SCALE := 1.12

## 瞄准判定不是一个圆，而是敌人那一列：左右 ±16、上方 34、下方 14。
## 因为玩家会瞄敌人头顶的血量/意图数字，圆形半径要么太小（瞄数字落空），
## 要么太大（误伤旁边那只）。
const TARGET_HALF_WIDTH := 16.0
const TARGET_UP := 34.0
const TARGET_DOWN := 14.0

const TYPE_COLORS := {
	Card.Type.ATTACK: Color(0.42, 0.26, 0.26),
	Card.Type.SKILL: Color(0.26, 0.32, 0.42),
	Card.Type.POWER: Color(0.30, 0.26, 0.42),
}

## 卡面边框：Aseprite 生成的 44×54 像素图（art/cards/），
## 中间是透明的，所以底色仍由 Background 的 TYPE_COLORS 决定，
## 三种类型只差描边内侧那圈 accent 色。
const FRAME_TEXTURES := {
	Card.Type.ATTACK: preload("res://art/cards/card_frame_attack.png"),
	Card.Type.SKILL: preload("res://art/cards/card_frame_skill.png"),
	Card.Type.POWER: preload("res://art/cards/card_frame_power.png"),
}

@export var card: Card
## P25：卡组视图里的卡是只读的——不装状态机、不能拖、不能打，但还能悬停看提示
@export var interactive := true

@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var background: ColorRect = $Background
@onready var frame: TextureRect = $Frame
@onready var rarity_bar: ColorRect = $Rarity
@onready var icon: TextureRect = $Icon
@onready var cost_label: Label = $Cost
@onready var title_label: Label = $Title
@onready var description_label: Label = $Description

var original_parent: Node = null
var original_index := 0
var home_global_position := Vector2.ZERO
var affordable := true

## 自检用：设成坐标就不再读真实鼠标
var debug_mouse := Vector2.INF


func _ready() -> void:
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_hover_start)
	mouse_exited.connect(_on_hover_end)
	if card:
		set_card(card)
	if interactive:
		state_machine.init(self)
	else:
		state_machine.disable_all()
		state_machine.queue_free()


func _gui_input(event: InputEvent) -> void:
	if interactive:
		state_machine.on_gui_input(event)


func set_card(new_card: Card) -> void:
	card = new_card
	if card == null:
		return
	cost_label.text = str(card.cost)
	title_label.text = card.title
	# 卡面上直接写效果，不用悬停也能看懂（"伤6"、"盾5"、"伤8 易伤2"）
	description_label.text = card.short_text()
	if card.icon:
		icon.texture = card.icon
	background.color = TYPE_COLORS.get(card.type, Color(0.42, 0.26, 0.26))
	frame.texture = FRAME_TEXTURES.get(card.type)
	# P27：卡顶那条 2px 色带就是稀有度——比改整张底色更不干扰图标
	rarity_bar.color = Card.RARITY_COLORS.get(card.rarity, Color(0.62, 0.6, 0.56))


## P11：能量不够时压暗 + 费用变红，一眼能看出这张现在打不出
func set_affordable(value: bool) -> void:
	affordable = value
	modulate = Color(1, 1, 1, 1) if value else Color(0.55, 0.55, 0.6, 0.95)
	cost_label.modulate = Color(1, 1, 1) if value else Color(1.9, 0.55, 0.55)


func _on_hover_start() -> void:
	if interactive:
		state_machine.on_mouse_entered()
	var tip := get_tree().get_first_node_in_group("card_tooltip")
	if tip and card:
		tip.show_text(card.tooltip_text, global_position + Vector2(size.x * 0.5, 0))


func _on_hover_end() -> void:
	if interactive:
		state_machine.on_mouse_exited()
	var tip := get_tree().get_first_node_in_group("card_tooltip")
	if tip:
		tip.hide_tip()


func remember_home() -> void:
	original_parent = get_parent()
	original_index = get_index()
	home_global_position = global_position


func mouse_position() -> Vector2:
	return debug_mouse if debug_mouse != Vector2.INF else get_global_mouse_position()


func is_over_play_zone() -> bool:
	var zone := get_tree().get_first_node_in_group("play_zone")
	if zone == null:
		return false
	return (zone as Control).get_global_rect().has_point(mouse_position())


func targets_under_mouse() -> Array:
	var out: Array = []
	var at := mouse_position()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node2D
		if node == null:
			continue
		var delta := node.global_position - at
		# delta.y > 0 表示鼠标在敌人上方（血量/意图那一带）
		if absf(delta.x) <= TARGET_HALF_WIDTH and delta.y >= -TARGET_DOWN and delta.y <= TARGET_UP:
			out.append(node)
	return out


func request_play(targets: Array) -> void:
	play_requested.emit(self, targets)


func return_home() -> void:
	if original_parent and get_parent() != original_parent:
		reparent(original_parent)
		var last := original_parent.get_child_count() - 1
		original_parent.move_child(self, mini(original_index, last))
	if state_machine.current_state and state_machine.current_state.state != CardState.State.BASE:
		state_machine.transition_to(state_machine.states[CardState.State.BASE])
