class_name Enemy
extends Node2D

## 敌人：贴图、血、意图、出手。
## 动作表在 EnemyStats.actions 里（数据），抽签逻辑在 EnemyAI 里（P14），
## 这里只负责"把抽到的动作演出来"。

signal died

const LUNGE_DISTANCE := 9.0
const LUNGE_TIME := 0.13
const BLOCK_BREAK_FX := preload("res://art/fx/block_break.png")

## 状态 → 火花颜色。冷色=削弱、暖色=强化、紫=易伤，玩家不用读数字也能判断"它被怎么样了"。
const STATUS_FX := {
	Stats.VULNERABLE: "shadow",
	Stats.WEAK: "ice",
	Stats.STRENGTH: "fire",
}

@export var stats: EnemyStats

@onready var sprite: Sprite2D = $Icon
@onready var stats_ui: StatsUI = $StatsUI
@onready var intent_ui: IntentUI = $IntentUI

var ai: EnemyAI
var current_action: EnemyAction
var _dying := false


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
	if stats.health <= 0 and not _dying:
		_dying = true
		died.emit()
		# 挂在父节点上播：自己下一行就 queue_free 了，特效要留在原地演完
		Juice.play_pixel(get_parent(), "explosions/cartoon-pow", global_position, {"z": 47, "scale": 0.45})
		# 消失前先冒一下烟，不然是"啪"地凭空不见
		Juice.play_fx(global_position, preload("res://art/fx/puff.png"), 16, 14.0, {"offset": Vector2(0, -6)})
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
	# 出手时播攻击帧条（和扑击补间同时进行，0.26s 对 3 帧 ≈ 0.25s）
	if current_action.type == EnemyAction.Type.ATTACK \
			and stats.attack_art != null and sprite.has_method("play_attack"):
		sprite.play_attack(stats.attack_art)
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
	Juice.pop_damage(global_position, dealt, absorbed, stats.get_status(Stats.VULNERABLE) > 0)
	# 有格挡吸收才播碎盾：纯掉血时播会重复表达"受伤"
	if absorbed > 0:
		Juice.play_fx(global_position, BLOCK_BREAK_FX, 16, 16.0, {"offset": Vector2(0, 2), "scale": 1.6})
	_flash()
	_squash()
	# 命中特效：8 点以上换大号，让"这一刀很疼"看得出来。
	# 注意选的都是 meta 里没有 actor 的效果——带 actor 的会自己画一个原装小人，
	# 贴在敌人身上就是两个人在打架（前面 hit-flash 就栽在这）。
	if dealt > 0:
		Juice.play_pixel(get_parent(), "impacts/crit-hit" if dealt >= 8 else "impacts/blunt-hit",
			global_position, {"z": 46})


func add_block(amount: int) -> void:
	stats.add_block(amount)
	Juice.pop_block(global_position, amount)


## P17：挨打时闪一下白光（用 modulate，不依赖材质）
func _flash() -> void:
	sprite.modulate = Color(2.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)


## 挨打时压扁再弹回，读起来比单纯闪白更像"被打了"
func _squash() -> void:
	sprite.scale = Vector2(1.2, 0.82)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)

## P17：被瞄准时把精灵放大一点（箭头由 CardTargetSelector 在 UI 层画，才不会被手牌挡住）
func set_targeted(value: bool) -> void:
	if sprite:
		sprite.scale = Vector2(1.18, 1.18) if value else Vector2.ONE

## 状态透传给 Stats（卡牌/敌人动作都通过这个方法挂状态）
func add_status(status: String, stacks: int) -> void:
	if stats:
		stats.add_status(status, stacks)
		# 挂状态也要看得见：在头顶炸一个"对应颜色"的小火花。
		# 用 hit-spark 换个调色板，而不是找一个"状态特效"——
		# pixelfx 的 status/* 全部带演员（会自己画一个小人），没法贴在人身上。
		Juice.play_pixel(get_parent(), "impacts/hit-spark", global_position + Vector2(0, -6),
			{"palette": String(STATUS_FX.get(status, "arcane")), "scale": 0.45, "z": 47})