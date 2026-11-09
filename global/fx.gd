extends Node

## 全局飘字。自己持有一个高层 CanvasLayer，所以任何脚本（敌人、玩家、遗物）
## 都能直接 Fx.pop_number()，不用关心当前场景结构。
##
## 坐标是屏幕坐标；本工程没有相机，所以世界坐标直接用。

var layer: CanvasLayer


func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)


func pop_number(world_pos: Vector2, amount: int, color := Color.WHITE, scale := 1.0) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", int(round(11 * scale)))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 100
	layer.add_child(label)

	label.position = world_pos + Vector2(-3, -16)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 11.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tween.chain().tween_callback(label.queue_free)


## 扣血：易伤时更大更红，格挡全吸收时显示灰
func pop_damage(world_pos: Vector2, amount: int, absorbed: int, vulnerable: bool) -> void:
	if amount <= 0 and absorbed > 0:
		pop_number(world_pos, absorbed, Color(0.62, 0.78, 0.95))
		return
	var color := Color(1.0, 0.42, 0.36) if vulnerable else Color(1.0, 0.92, 0.88)
	var size := 1.45 if vulnerable else 1.0
	pop_number(world_pos, amount, color, size)


## 加格挡
func pop_block(world_pos: Vector2, amount: int) -> void:
	pop_number(world_pos, amount, Color(0.62, 0.80, 1.0))
