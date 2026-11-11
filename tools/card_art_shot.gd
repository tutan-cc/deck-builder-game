extends Node

## 专用截图工具：加载战斗场景，等手牌发完，存 256x144 原始渲染图。
## 用 get_viewport().get_texture() 而不是抓窗口 —— 视口模式下的渲染纹理
## 就是 256x144，不受系统 DPI 缩放影响，这才是判断像素美术的正确依据。
##
## 连拍两张（间隔 0.35s）：角色是逐帧动画，两张图有差异才能证明帧真的在推进，
## 否则只能看出"贴图换对了"，看不出"动没动"。

const OUT := "res://shots/art_after.png"
const OUT2 := "res://shots/art_after_2.png"


func _ready() -> void:
	# 默认拍战斗场景；命令行 `-- <scene>` 可以改成任意场景
	# 用法: godot --path <proj> res://tools/card_art_shot.tscn -- res://scenes/map/map.tscn
	var args := OS.get_cmdline_user_args()
	var scene_path := "res://scenes/battle/battle.tscn"
	if args.size() > 0 and args[0].begins_with("res://"):
		scene_path = args[0]
	print("SHOT_SCENE %s" % scene_path)
	var packed: PackedScene = load(scene_path)
	var battle: Node = packed.instantiate()
	add_child(battle)
	# 发牌有入场动画，多等几帧
	for i in 24:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT1 size=%dx%d err=%d" % [img.get_width(), img.get_height(), img.save_png(OUT)])

	# 等约 0.35 秒再拍一张
	var t := 0.0
	while t < 0.35:
		await get_tree().process_frame
		t += get_process_delta_time()
	await RenderingServer.frame_post_draw
	var img2 := get_viewport().get_texture().get_image()
	print("SHOT2 err=%d" % img2.save_png(OUT2))

	get_tree().quit()
