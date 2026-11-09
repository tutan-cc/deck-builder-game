extends Node

## P17：震屏。注册一个"要抖的节点"，之后就只管调 shake()。
## 只抖世界层（Node2D），UI 在 CanvasLayer 上，不会跟着晃——这是故意的。

var _target: CanvasItem
var _origin := Vector2.ZERO


func register_target(node: CanvasItem) -> void:
	_target = node
	_origin = node.position


func shake(amount := 3.0, duration := 0.2) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if _target.position != _origin:
		_target.position = _origin

	var steps := 4
	var tween := create_tween()
	for i in steps:
		var offset := Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tween.tween_property(_target, "position", _origin + offset, duration / (steps + 1))
	tween.tween_property(_target, "position", _origin, duration / (steps + 1))
