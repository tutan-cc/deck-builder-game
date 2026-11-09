class_name Enemy
extends Node2D

## 敌人：贴图、血、意图、出手。
## 动作表在 EnemyStats.actions 里（数据），抽签逻辑在 EnemyAI 里（P14），
## 这里只负责"把抽到的动作演出来"。

signal died

const LUNGE_DISTANCE := 9.0
const LUNGE_TIME := 0.13

@export var stats: EnemyStats

@onready var sprite: Sprite2D = $Icon
@onready var stats_ui: StatsUI = $StatsUI
@onready var intent_ui: IntentUI = $IntentUI

var ai: EnemyAI
var current_action: EnemyAction


func _ready() -> void:
	if stats:
		bind_stats(stats)


func setup(new_stats: EnemyStats) -> void:
	stats = new_stats
	bind_stats(stats)


func bind_stats(new_stats: EnemyStats) -> void:
	stats = new_stats
	stats_ui.bind(stats)
	if stats.art:
		sprite.texture = stats.art
	ai = EnemyAI.new()
	ai.actions = stats.actions
	intent_ui.clear()
	if not stats.stats_changed.is_connected(_on_stats_changed):
		stats.stats_changed.connect(_on_stats_changed)


func _on_stats_changed() -> void:
	if stats.health <= 0:
		died.emit()
		queue_free()


## 玩家回合开始时抽这一轮要做什么，并显示在头顶
func pick_intent() -> void:
	current_action = ai.pick() if ai else null
	intent_ui.show_action(current_action)


## 执行意图：先扑向玩家，再结算，最后清掉意图
## 结算走 action.execute()，所以将来写"特殊动作子类"不需要改这里
func execute(target: Node) -> void:
	if current_action == null:
		return
	await _lunge(target)
	current_action.execute(self, target)
	intent_ui.clear()


func _lunge(target: Node) -> void:
	if target == null:
		return
	var home := position
	var target_pos: Vector2 = (target as Node2D).global_position
	var dir: Vector2 = (target_pos - global_position).normalized()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home + dir * LUNGE_DISTANCE, LUNGE_TIME)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", home, LUNGE_TIME)
	await tween.finished


func take_damage(amount: int) -> void:
	var block_before: int = stats.block
	stats.take_damage(amount)
	var dealt: int = maxi(0, amount - block_before)
	var absorbed: int = amount - dealt
	Fx.pop_damage(global_position, dealt, absorbed, stats.get_status(Stats.VULNERABLE) > 0)
	_flash()


func add_block(amount: int) -> void:
	stats.add_block(amount)
	Fx.pop_block(global_position, amount)


## P17：挨打时闪一下白光（用 modulate，不依赖材质）
func _flash() -> void:
	sprite.modulate = Color(2.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)

## P17：被瞄准时把精灵放大一点（箭头由 CardTargetSelector 在 UI 层画，才不会被手牌挡住）
func set_targeted(value: bool) -> void:
	if sprite:
		sprite.scale = Vector2(1.18, 1.18) if value else Vector2.ONE

## 状态透传给 Stats（卡牌/敌人动作都通过这个方法挂状态）
func add_status(status: String, stacks: int) -> void:
	if stats:
		stats.add_status(status, stacks)