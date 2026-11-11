class_name TopBar
extends PanelContainer

## P26：战斗顶部栏。把"层数 / 金币 / 抽牌堆 / 弃牌堆 / 结束回合"收进一条，
## 原来它们散在屏幕四角，加了金币之后就没地方放了。

signal end_turn_pressed
signal draw_pressed
signal discard_pressed

@onready var depth_label: Label = $Row/Depth
@onready var gold_label: Label = $Row/Gold
@onready var energy_label: Label = $Row/Energy
@onready var draw_button: Button = $Row/Draw
@onready var discard_button: Button = $Row/Discard
@onready var end_turn_button: Button = $Row/EndTurn


func _ready() -> void:
	end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	draw_button.pressed.connect(func() -> void: draw_pressed.emit())
	discard_button.pressed.connect(func() -> void: discard_pressed.emit())


func set_depth(value: int) -> void:
	depth_label.text = "第 %d 层" % value


func set_gold(value: int) -> void:
	gold_label.text = "◆ %d" % value


func set_piles(draw_count: int, discard_count: int) -> void:
	draw_button.text = "抽 %d" % draw_count
	discard_button.text = "弃 %d" % discard_count


func set_end_enabled(value: bool) -> void:
	end_turn_button.disabled = not value

## 能量单独放顶栏：原来它贴在玩家头顶，和血量/护盾挤在一起看不清
func set_energy(current: int, maximum: int) -> void:
	energy_label.text = "%d/%d" % [current, maximum]
	energy_label.add_theme_color_override("font_color",
		Color(1, 0.87, 0.42) if current > 0 else Color(0.75, 0.55, 0.5))