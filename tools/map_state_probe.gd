extends Node

## 复现"第 2 层 · 商店"这个状态，检查：
##   1) available_rooms() 到底是不是空的
##   2) 可用房间的节点是不是真的能接鼠标

func _ready() -> void:
	RunState.start_run(Character.warrior())

	var idx := -1
	for i in RunState.map_rooms.size():
		var r: Room = RunState.map_rooms[i]
		if r.row == 1 and r.type == Room.Type.SHOP:
			idx = i
			break
	if idx < 0:
		for i in RunState.map_rooms.size():
			if RunState.map_rooms[i].row == 1:
				idx = i
				break
	if idx < 0:
		print("STATE 找不到第二层房间")
		get_tree().quit()
		return

	RunState.current_room = idx
	var room: Room = RunState.map_rooms[idx]
	print("STATE room=%s row=%d next=%s" % [room.label(), room.row, str(room.next)])
	print("STATE available=%s" % str(RunState.available_rooms()))

	var map: Control = load("res://scenes/map/map.tscn").instantiate()
	add_child(map)
	await get_tree().create_timer(0.7).timeout
	for i in RunState.available_rooms():
		var holder: Control = map.nodes[i]
		print("STATE avail_idx=%d pos=%s size=%s filter=%d visible=%s" % [
			i, str(holder.position), str(holder.size), holder.mouse_filter, str(holder.is_visible_in_tree())])
	print("STATE 房间总数=%d 行数=%d" % [RunState.map_rooms.size(), MapGenerator.ROWS])
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	print("STATE shot err=%d" % img.save_png("res://shots/map_state.png"))
	get_tree().quit()
