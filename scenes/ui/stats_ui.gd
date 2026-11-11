class_name StatsUI
extends Control

## 数值显示。**只订阅，不查询**：绑定时连上 stats_changed，之后每次变化自动重画。
## 血条、数字、飘字都可以各订阅一份，互不知道对方存在。
##
## 图标化说明：血量 / 格挡 / 状态原来都是纯文字，现在前面挂图标。
## 数字仍然用文字——图标负责"这是什么"，文字负责"多少"。

@export var stats: Stats

const STATUS_ICONS := {
	Stats.STRENGTH: preload("res://art/ui/status_strength.png"),
	Stats.VULNERABLE: preload("res://art/ui/status_vulnerable.png"),
	Stats.WEAK: preload("res://art/ui/status_weak.png"),
}
## 固定顺序：力量 → 易伤 → 虚弱。顺序稳定，玩家扫一眼就知道在哪找。
const STATUS_ORDER := [Stats.STRENGTH, Stats.VULNERABLE, Stats.WEAK]

## 上一次各状态的层数：用来判断这次重建是"层数涨了"还是"只是掉血了"
var _last_stacks := {}

@onready var shield: TextureRect = $Shield
@onready var health_label: Label = $Health
@onready var block_label: Label = $Block
@onready var status_row: HBoxContainer = $Statuses


func _ready() -> void:
	if stats:
		bind(stats)


func bind(new_stats: Stats) -> void:
	if stats and stats.stats_changed.is_connected(_refresh):
		stats.stats_changed.disconnect(_refresh)
	stats = new_stats
	_last_stacks.clear()
	if stats == null:
		return
	if not stats.stats_changed.is_connected(_refresh):
		stats.stats_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if stats == null:
		return
	health_label.text = str(stats.health)
	# 盾徽和数字一起显示/隐藏：没有格挡时不该占位
	block_label.visible = stats.block > 0
	shield.visible = stats.block > 0
	block_label.text = str(stats.block)
	_rebuild_statuses()


## 状态条是动态的（可能没有、可能有 1~3 种），所以每次重建而不是复用节点。
func _rebuild_statuses() -> void:
	if status_row == null:
		return
	for child in status_row.get_children():
		status_row.remove_child(child)
		child.queue_free()
	for status in STATUS_ORDER:
		var stacks := stats.get_status(status)
		if stacks <= 0:
			_last_stacks.erase(status)
			continue
		# 只在"层数涨了"的时候弹一下；每次受伤都会重建，不区分的话每个数字都在抖
		var grew := stacks > int(_last_stacks.get(status, 0))
		_last_stacks[status] = stacks
		var icon := TextureRect.new()
		icon.texture = STATUS_ICONS[status]
		icon.custom_minimum_size = Vector2(8, 8)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		status_row.add_child(icon)

		var num := Label.new()
		num.text = str(stacks)
		num.add_theme_font_size_override("font_size", 12)
		num.add_theme_color_override("font_color", Color(0.96, 0.76, 0.47))
		num.add_theme_color_override("font_outline_color", Color(0.07, 0.06, 0.06))
		num.add_theme_constant_override("outline_size", 2)
		status_row.add_child(num)

		if grew:
			_pop(num)


## 层数涨了：数字从 2 倍缩回 1 倍，读起来是"又多了一层"
func _pop(node: Control) -> void:
	node.pivot_offset = Vector2(6, 8)
	node.scale = Vector2(2.0, 2.0)
	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22)
