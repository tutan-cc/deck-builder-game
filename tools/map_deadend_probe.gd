extends Node

## 地图死胡同探测：随机生成大量地图，统计"不是最后一行却没有下一间"的房间。
## 这类房间一旦走进去，地图上就没有可点的房间 —— 玩家会硬卡住。

const N := 400


func _ready() -> void:
	var bad := 0
	var bad_maps := {}
	var total := 0
	for n in N:
		var rooms: Array = MapGenerator.generate()
		total += rooms.size()
		var map_has_bad := false
		for i in rooms.size():
			var room: Room = rooms[i]
			if room.next.is_empty() and room.row < MapGenerator.ROWS - 1:
				bad += 1
				map_has_bad = true
		if map_has_bad:
			bad_maps[n] = true
	print("DEADEND rooms_bad=%d / total=%d  maps_bad=%d / %d" % [bad, total, bad_maps.size(), N])
	get_tree().quit()
