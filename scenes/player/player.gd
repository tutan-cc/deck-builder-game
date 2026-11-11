class_name Player
extends Node2D

## 玩家：数值在 CharacterStats，这里只负责显示和挨打。

signal died

@export var stats: CharacterStats

## 攻击帧条按当前角色贴图选：战士用剑、猎手用弓。
## 用贴图文件名做键，这样换角色不用改这里。
const ATTACK_ARTS := {
	"actor_warrior": preload("res://art/actors/actor_warrior_att.png"),
	"actor_hunter": preload("res://art/actors/actor_hunter_att.png"),
}

const BLOCK_BREAK_FX := preload("res://art/fx/block_break.png")

## 状态 → 火花颜色，和敌人那边保持同一套（冷=削弱、暖=强化、紫=易伤）
const STATUS_FX := {
	Stats.VULNERABLE: "shadow",
	Stats.WEAK: "ice",
	Stats.STRENGTH: "fire",
}

@onready var sprite: Sprite2D = $Icon
@onready var stats_ui: StatsUI = $StatsUI
@onready var energy_label: Label = $Energy


func _ready() -> void:
	if stats:
		bind_stats(stats)


func setup(new_stats: CharacterStats) -> void:
	bind_stats(new_stats)


func bind_stats(new_stats: CharacterStats) -> void:
	stats = new_stats
	stats_ui.bind(stats)
	if not stats.stats_changed.is_connected(_on_stats_changed):
		stats.stats_changed.connect(_on_stats_changed)
	_refresh_energy()


func _on_stats_changed() -> void:
	_refresh_energy()
	if stats.health <= 0:
		died.emit()


func _refresh_energy() -> void:
	energy_label.text = "%d/%d" % [stats.energy, stats.max_energy]


func take_damage(amount: int) -> void:
	# P37：遗物减伤（荆棘环这种）在进 Stats 之前生效
	var reduced := maxi(0, amount - RunState.damage_reduction())
	var block_before: int = stats.block
	stats.take_damage(reduced)
	var dealt: int = maxi(0, reduced - block_before)
	Juice.pop_damage(global_position, dealt, reduced - dealt, stats.get_status(Stats.VULNERABLE) > 0)
	if reduced - dealt > 0:
		Juice.play_fx(global_position, BLOCK_BREAK_FX, 16, 16.0, {"offset": Vector2(0, 2), "scale": 1.6})
	_flash()
	_squash()
	# 敌人扑上来打在玩家身上，也要有落点（原来只有红屏 + 抖动，看不出打在哪）
	if dealt > 0:
		Juice.play_pixel(get_parent(), "impacts/blunt-hit", global_position, {"z": 46})


func add_block(amount: int) -> void:
	stats.add_block(amount)
	Juice.pop_block(global_position, amount)
	# 加格挡给一圈"挡下"的冷色火花：这是玩家唯一能看到的"我这回合变硬了"。
	# 用 ice 调色板和攻击的暖色分开——不然打击和防御看起来是同一个特效。
	Juice.play_pixel(get_parent(), "impacts/parry", global_position + Vector2(0, -4),
		{"z": 45, "palette": "ice"})


func spend_energy(cost: int) -> bool:
	if stats.energy < cost:
		return false
	stats.energy = stats.energy - cost
	return true


func start_turn() -> void:
	stats.clear_block()
	stats.reset_energy()


func _flash() -> void:
	sprite.modulate = Color(2.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)


## 出牌时播攻击动作。没有对应帧条就静默跳过，不影响出牌逻辑。
func play_attack() -> void:
	if sprite == null or not sprite.has_method("play_attack"):
		return
	sprite.play_attack(ATTACK_ARTS.get(_art_key(), ATTACK_ARTS["actor_warrior"]))


func _art_key() -> String:
	if stats and stats.art:
		return str(stats.art.resource_path).get_file().get_basename()
	return "actor_warrior"


## 挨打时压扁再弹回：比单纯闪白更能读出"被打到了"
func _squash() -> void:
	sprite.scale = Vector2(1.18, 0.84)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)

## 状态透传给 Stats（卡牌/敌人动作都通过这个方法挂状态）
func add_status(status: String, stacks: int) -> void:
	if stats:
		stats.add_status(status, stacks)
		# 敌人给玩家挂状态（虚弱/易伤）时，自己身上也要有反应，否则像是凭空变成的
		Juice.play_pixel(get_parent(), "impacts/hit-spark", global_position + Vector2(0, -6),
			{"palette": String(STATUS_FX.get(status, "arcane")), "scale": 0.45, "z": 47})