class_name Player
extends Node2D

## 玩家：数值在 CharacterStats，这里只负责显示和挨打。

signal died

@export var stats: CharacterStats

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
	Fx.pop_damage(global_position, dealt, reduced - dealt, stats.get_status(Stats.VULNERABLE) > 0)
	_flash()


func add_block(amount: int) -> void:
	stats.add_block(amount)
	Fx.pop_block(global_position, amount)


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

## 状态透传给 Stats（卡牌/敌人动作都通过这个方法挂状态）
func add_status(status: String, stacks: int) -> void:
	if stats:
		stats.add_status(status, stacks)