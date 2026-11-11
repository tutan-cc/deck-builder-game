class_name SpriteAnim
extends Sprite2D

## 把「横排帧条」当动画播：帧数 = 贴图宽 / 帧宽。
##
## 为什么不用 AnimatedSprite2D：enemy.gd / player.gd 里是
## `sprite.texture = stats.art` 直接换贴图，换成 AnimatedSprite2D 会把这些
## 赋值全部弄坏。这个脚本保持 Sprite2D 接口不变，只额外做帧循环。
##
## 两种播放模式：
##   待机 —— 循环，帧数取自当前贴图
##   攻击 —— play_attack() 切到攻击帧条，播完一遍自动切回待机

@export var frame_width: int = 16
@export var fps: float = 7.0
@export var attack_fps: float = 12.0

var _frames: int = 1
var _fps: float = 7.0
var _t: float = 0.0
var _last_tex: Texture2D = null
var _idle_tex: Texture2D = null
var _attacking := false


func _ready() -> void:
	_fps = fps
	_refresh()


func _refresh() -> void:
	_last_tex = texture
	if texture == null:
		_frames = 1
		return
	# 显式浮点除：两边都是 int 时 GDScript 会警告 INTEGER_DIVISION（本工程把它设成了 error 级）
	_frames = maxi(1, int(texture.get_width() / float(maxi(1, frame_width))))
	hframes = _frames
	vframes = 1
	_t = 0.0
	frame = 0


## 播一次攻击帧条，结束自动回待机贴图。
func play_attack(tex: Texture2D) -> void:
	if tex == null:
		return
	if not _attacking:
		_idle_tex = texture
	_attacking = true
	_fps = attack_fps
	texture = tex
	_refresh()


func is_attacking() -> bool:
	return _attacking


func _process(delta: float) -> void:
	# 贴图是运行时赋进来的；攻击期间不要被外部赋值干扰
	if not _attacking and texture != _last_tex:
		_refresh()
	if _frames <= 1:
		return
	_t += delta
	if _attacking and _t >= float(_frames) / _fps:
		_attacking = false
		_fps = fps
		texture = _idle_tex
		_refresh()
		return
	var f := int(_t * _fps) % _frames
	if f != frame:
		frame = f
