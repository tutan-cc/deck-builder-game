class_name StatsUI
extends Control

## 数值显示。**只订阅，不查询**：绑定时连上 stats_changed，之后每次变化自动重画。
## 血条、数字、飘字都可以各订阅一份，互不知道对方存在。

@export var stats: Stats

@onready var health_label: Label = $Health
@onready var block_label: Label = $Block
@onready var status_label: Label = $Statuses


func _ready() -> void:
	if stats:
		bind(stats)


func bind(new_stats: Stats) -> void:
	if stats and stats.stats_changed.is_connected(_refresh):
		stats.stats_changed.disconnect(_refresh)
	stats = new_stats
	if stats == null:
		return
	if not stats.stats_changed.is_connected(_refresh):
		stats.stats_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if stats == null:
		return
	health_label.text = str(stats.health)
	block_label.visible = stats.block > 0
	block_label.text = str(stats.block)
	if status_label:
		status_label.text = stats.status_text()
