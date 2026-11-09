extends Control

## P39：营地。休息回血 / 升级一张卡（自选）/ 离开。
## 火焰用 GPUParticles2D，底下叠一个暖色光斑。

@onready var info: Label = $Box/Info
@onready var rest_button: Button = $Box/Row/Rest
@onready var upgrade_button: Button = $Box/Row/Upgrade
@onready var leave_button: Button = $Box/Row/Leave
@onready var glow: ColorRect = $Glow
@onready var menu: CardMenu = $CardMenu

var _rested := false
var _upgraded := false


func _ready() -> void:
	leave_button.pressed.connect(_leave)
	rest_button.pressed.connect(_rest)
	upgrade_button.pressed.connect(_ask_upgrade)
	menu.card_selected.connect(_on_card_selected)
	_pulse()
	_refresh()


func _pulse() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.55, 0.7)
	tween.tween_property(glow, "modulate:a", 1.0, 0.7)


func _max_hp() -> int:
	return RunState.character.max_health if RunState.character else 35


func _current_hp() -> int:
	var max_hp := _max_hp()
	return max_hp if RunState.current_health < 0 else RunState.current_health


func _refresh() -> void:
	info.text = "生命 %d / %d · 卡组 %d 张" % [_current_hp(), _max_hp(), RunState.deck.size()]


func _rest() -> void:
	if _rested:
		return
	_rested = true
	var healed := RunState.heal(int(ceil(_max_hp() * 0.3)))
	rest_button.disabled = true
	info.text = "恢复了 %d 点生命（%d / %d）" % [healed, _current_hp(), _max_hp()]
	Sfx.play("block")


## P39：升级哪张交给玩家选，不再随机
func _ask_upgrade() -> void:
	if _upgraded or RunState.deck.is_empty():
		return
	menu.open(RunState.deck, "选择要升级的卡", true)


func _on_card_selected(card: Card) -> void:
	if _upgraded:
		return
	var index := RunState.deck.find(card)
	if index < 0:
		return
	var upgraded := CardLibrary.upgrade(card)
	RunState.deck[index] = upgraded
	_upgraded = true
	upgrade_button.disabled = true
	info.text = "%s → %s" % [card.title, upgraded.title]
	Sfx.play("axe")


func _leave() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
