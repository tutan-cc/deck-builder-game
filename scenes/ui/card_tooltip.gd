class_name CardTooltip
extends PanelContainer

## P11：卡牌悬浮提示。挂在 UILayer 上单独显示，而不是塞进卡里——
## 卡只有 40×56，塞进去必然被裁掉。

@onready var label: Label = $Margin/Label

var _visible := false


func _ready() -> void:
	hide_tip()


func show_text(text: String, at: Vector2) -> void:
	if text.is_empty():
		return
	label.text = text
	visible = true
	_visible = true
	# 256×144 的屏幕上没有空间跟着卡片飘：固定在手牌正上方居中，
	# 永远不会被屏幕边缘裁掉。at 只是提示"哪张卡"，不参与定位。
	var size_now := get_combined_minimum_size()
	global_position = Vector2(roundf(128.0 - size_now.x * 0.5), 6.0)


func hide_tip() -> void:
	visible = false
	_visible = false


func is_showing() -> bool:
	return _visible
