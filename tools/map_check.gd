extends SceneTree
func _initialize() -> void:
	for trial in 8:
		var rooms = MapGenerator.generate()
		var crossing := 0
		var edges := []
		for i in rooms.size():
			for j in rooms[i].next:
				edges.append([i, j])
		for x in edges.size():
			for y in range(x + 1, edges.size()):
				var e1 = edges[x]; var e2 = edges[y]
				if e1[0] in [e2[0], e2[1]] or e1[1] in [e2[0], e2[1]]: continue
				var a = Vector2(rooms[e1[0]].col * 74.0, rooms[e1[0]].row * 17.0)
				var b = Vector2(rooms[e1[1]].col * 74.0, rooms[e1[1]].row * 17.0)
				var c = Vector2(rooms[e2[0]].col * 74.0, rooms[e2[0]].row * 17.0)
				var d = Vector2(rooms[e2[1]].col * 74.0, rooms[e2[1]].row * 17.0)
				if (b-a).cross(c-a) * (b-a).cross(d-a) < 0.0 and (d-c).cross(a-c) * (d-c).cross(b-c) < 0.0:
					crossing += 1
		var dead := 0
		for r in rooms:
			if r.next.is_empty() and r.row < MapGenerator.ROWS - 1: dead += 1
		var chains := 0
		for i in rooms.size():
			for j in rooms[i].next:
				var a_type: int = rooms[i].type
				var b_type: int = rooms[j].type
				if a_type == b_type and a_type in [Room.Type.CAMPFIRE, Room.Type.SHOP]:
					chains += 1
		print("MAP trial%d rooms=%d edges=%d crossings=%d dead_ends=%d same_type_chains=%d" % [trial, rooms.size(), edges.size(), crossing, dead, chains])
	quit()
