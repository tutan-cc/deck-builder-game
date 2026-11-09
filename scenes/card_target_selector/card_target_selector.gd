class_name CardTargetSelector
extends Node2D

## 瞄准弧线（P4）。从卡的中心画一条到鼠标的曲线。
## 用二次贝塞尔而不是直线：直线和卡面重叠时看不清"从哪出来"。

@onready var line: Line2D = $Line
@onready var arrow: Sprite2D = $Arrow

var card: CardUI
var _highlighted: Node = null
const ARROW_OFFSET := Vector2(0, 16)   # 敌人下方、箭头朝上：上方被卡和顶栏占满了

const SEGMENTS := 12


func _ready() -> void:
	set_process(false)
	line.visible = false


func start(source: CardUI) -> void:
	card = source
	line.visible = true
	set_process(true)


func stop() -> void:
	if is_instance_valid(_highlighted) and _highlighted.has_method("set_targeted"):
		_highlighted.set_targeted(false)
	_highlighted = null
	if arrow:
		arrow.visible = false
	if is_instance_valid(card) and card.card:
		card.background.color = CardUI.TYPE_COLORS.get(card.card.type, Color(0.42, 0.26, 0.26))
	card = null
	line.visible = false
	set_process(false)
	line.clear_points()


func _process(_delta: float) -> void:
	if card == null:
		return
	# 起点用"卡原来的位置"，不是当前位置：卡跟着鼠标走，用当前位置弧线会缩成一个点
	var from := card.home_global_position + card.size * 0.5
	var to := card.mouse_position()
	line.points = build_arc(from, to)
	_highlight_target(to)


## P17：鼠标下的敌人头顶亮箭头（同一时刻只有一个）
func _highlight_target(_at: Vector2) -> void:
	# 和松手判定用同一套"列"判定，看到箭头就等于能打中
	var picked: Array = card.targets_under_mouse() if card else []
	var hit: Node = picked[0] if picked.size() > 0 else null
	if hit == _highlighted:
		return
	if is_instance_valid(_highlighted) and _highlighted.has_method("set_targeted"):
		_highlighted.set_targeted(false)
	_highlighted = hit
	if is_instance_valid(_highlighted) and _highlighted.has_method("set_targeted"):
		_highlighted.set_targeted(true)
	_update_arrow()


## 拖着的卡有 44×54，几乎盖满敌人——箭头放哪都会被挡住。
## 所以改成给"卡本身"染色表示已锁定目标，世界侧只保留敌人放大。
func _update_arrow() -> void:
	if arrow:
		arrow.visible = false
	if card == null:
		return
	var locked := is_instance_valid(_highlighted)
	var base: Color = CardUI.TYPE_COLORS.get(card.card.type, Color(0.42, 0.26, 0.26)) if card.card else Color(0.42, 0.26, 0.26)
	card.background.color = base.lerp(Color(0.30, 0.52, 0.34), 0.75) if locked else base


func build_arc(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var delta := to - from
	var normal := Vector2(-delta.y, delta.x).normalized()
	# 弧度随距离增长，但有上限，免得贴脸时甩出一个大圈
	var bulge := minf(delta.length() * 0.22, 16.0)
	var control := (from + to) * 0.5 + normal * bulge
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		var a := from.lerp(control, t)
		var b := control.lerp(to, t)
		points.append(a.lerp(b, t))
	return points
