extends Node

## 地图 / 营地的截图自检。

func _ready() -> void:
	RunState.start_run(Character.warrior())
	print("T map rooms=%d available=%s" % [
		RunState.map_rooms.size(), str(RunState.available_rooms())])

	var map_scene: Control = load("res://scenes/map/map.tscn").instantiate()
	add_child(map_scene)
	await get_tree().create_timer(0.4).timeout
	await shot("res://shots/p31_map")

	# 模拟"走进第一行的第一个房间"
	var first: int = RunState.available_rooms()[0]
	RunState.current_room = first
	RunState.depth = RunState.map_rooms[first].row + 1
	RunState.current_health = 18
	var next_rooms := RunState.available_rooms()
	print("T after_enter next=%s depth=%d" % [str(next_rooms), RunState.depth])

	map_scene.queue_free()
	await frames(2)

	var camp: Control = load("res://scenes/campfire/campfire.tscn").instantiate()
	add_child(camp)
	await get_tree().create_timer(0.3).timeout
	await shot("res://shots/p39_campfire")
	var before: int = RunState.current_health
	camp._rest()
	await frames(2)
	print("T campfire: hp %d -> %d" % [before, RunState.current_health])
	var deck_before: int = RunState.deck.size()
	camp._ask_upgrade()                      # 打开选卡面板
	await frames(1)
	var pick: Card = RunState.deck[0]
	camp._on_card_selected(pick)             # 选中第一张
	await frames(1)
	print("T campfire upgrade: deck=%d %s" % [deck_before, RunState.deck[0].title])
	camp.queue_free()
	await frames(2)

	# 商店房间：造一个假房间塞进地图，验证买卡扣钱
	var shop := Room.new()
	shop.type = Room.Type.SHOP
	RunState.map_rooms.append(shop)
	RunState.current_room = RunState.map_rooms.size() - 1
	RunState.gold = 100
	var room_scene: Control = load("res://scenes/rooms/room_event.tscn").instantiate()
	add_child(room_scene)
	await get_tree().create_timer(0.3).timeout
	await shot("res://shots/p33_shop")
	print("T shop: cards=%d gold=%d" % [room_scene.cards_row.get_child_count(), RunState.gold])
	room_scene.queue_free()

	get_tree().quit()


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(path: String) -> void:
	if not path.ends_with(".png"):
		path += ".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("SHOT %s err=%d" % [path, img.save_png(path)])
