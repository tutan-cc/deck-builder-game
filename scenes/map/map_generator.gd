class_name MapGenerator

## P32–P34：地图生成。
## 做法是"逐行生成 + 就近连线"，不是完整的分支图算法——
## 保证每一行都走得通、每个房间都有父亲，就已经能玩了。

const ROWS := 15
const COLS := 7

## P31 视频里的原始数值：MONSTER 10 / SHOP 2.5 / CAMPFIRE 4
## 这里补上 EVENT / ELITE，比例大致保持同量级
const TYPE_WEIGHTS := {
	Room.Type.BATTLE: 10.0,
	Room.Type.SHOP: 2.5,
	Room.Type.CAMPFIRE: 4.0,
	Room.Type.EVENT: 3.0,
	Room.Type.ELITE: 1.5,
}


static func generate() -> Array:
	var rooms: Array = []
	var rows: Array = []          # 每行房间在 rooms 里的下标

	for row in ROWS:
		var count := 1 if row == ROWS - 1 else (randi_range(3, 4) if row == 0 else randi_range(2, 4))
		# P38：Boss 固定在中间列
		var cols := [int(floor(COLS * 0.5))] if row == ROWS - 1 else _pick_columns(count)
		var row_indices: Array = []
		for col in cols:
			var room := Room.new()
			room.row = row
			room.col = col
			room.type = _pick_type(row)
			rooms.append(room)
			row_indices.append(rooms.size() - 1)
		rows.append(row_indices)

	# 连线：每个房间连到下一行里列差 ≤1 的；没人连的房间补一条最短路
	for row in ROWS - 1:
		var current: Array = rows[row]
		var below: Array = rows[row + 1]
		var has_parent := {}
		for index in current:
			var room: Room = rooms[index]
			for target in below:
				var other: Room = rooms[target]
				if absi(other.col - room.col) <= 1:
					if not room.next.has(target):
						room.next.append(target)
						has_parent[target] = true
		for target in below:
			if has_parent.has(target):
				continue
			# 兜底：这间没人连，接给上行最近的一间
			var best: int = current[0]
			for index in current:
				if absi(rooms[index].col - rooms[target].col) < absi(rooms[best].col - rooms[target].col):
					best = index
			rooms[best].next.append(target)

	# P38：每间战斗房自己带一份遭遇战资源（视频里是 boss_room.battle_stats = ...）
	_assign_battles(rooms)

	# 修死胡同：连不上下一行的房间，接给下行最近的一间
	_repair_dead_ends(rooms)

	# P34：相邻两层不能是同一类（连续两个营地/商店很浪费）
	_avoid_type_chains(rooms)

	# P33：连完之后把"X 形交叉"的边删掉，线别互相穿
	_remove_crossings(rooms)
	return rooms


static func _repair_dead_ends(rooms: Array) -> void:
	var by_row := {}
	for i in rooms.size():
		var room: Room = rooms[i]
		if not by_row.has(room.row):
			by_row[room.row] = []
		by_row[room.row].append(i)

	for i in rooms.size():
		var room: Room = rooms[i]
		if not room.next.is_empty():
			continue
		var below: Array = by_row.get(room.row + 1, [])
		if below.is_empty():
			continue          # 最后一行（Boss）本来就没有下一行
		var best: int = below[0]
		for j in below:
			if absi(rooms[j].col - room.col) < absi(rooms[best].col - room.col):
				best = j
		room.next.append(best)


## 两段线是否真的交叉（标准叉积判定；共端点的不算）
static func _crosses(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var o1 := (b - a).cross(c - a)
	var o2 := (b - a).cross(d - a)
	var o3 := (d - c).cross(a - c)
	var o4 := (d - c).cross(b - c)
	return o1 * o2 < 0.0 and o3 * o4 < 0.0


static func _room_center(room: Room) -> Vector2:
	return Vector2(room.col * 74.0, room.row * 17.0)


static func _remove_crossings(rooms: Array) -> void:
	var edges: Array = []
	for i in rooms.size():
		for j in rooms[i].next:
			edges.append([i, j])

	var dropped := {}
	# 逐对检查；删边时优先保住"来源房间的唯一出路"
	for x in edges.size():
		if dropped.has(x):
			continue
		for y in range(x + 1, edges.size()):
			if dropped.has(y):
				continue
			var e1: Array = edges[x]
			var e2: Array = edges[y]
			if e1[0] == e2[0] or e1[0] == e2[1] or e1[1] == e2[0] or e1[1] == e2[1]:
				continue
			var p1 := _room_center(rooms[e1[0]])
			var p2 := _room_center(rooms[e1[1]])
			var p3 := _room_center(rooms[e2[0]])
			var p4 := _room_center(rooms[e2[1]])
			if not _crosses(p1, p2, p3, p4):
				continue

			if _has_other_edge(edges, dropped, y, edges[y][0]):
				dropped[y] = true
			elif _has_other_edge(edges, dropped, x, edges[x][0]):
				dropped[x] = true
			# 两边都只剩这一条：宁可让线交叉，也不制造死胡同

	# 用保留下来的边整体重建 next
	for room in rooms:
		room.next.clear()
	for k in edges.size():
		if dropped.has(k):
			continue
		var from: Room = rooms[edges[k][0]]
		from.next.append(edges[k][1])


static func _has_other_edge(edges: Array, dropped: Dictionary, skip: int, source: int) -> bool:
	for k in edges.size():
		if k == skip or dropped.has(k):
			continue
		if edges[k][0] == source:
			return true
	return false

static func _pick_columns(count: int) -> Array:
	var all := range(COLS)
	all.shuffle()
	var picked := all.slice(0, count)
	picked.sort()
	return picked


static func _pick_type(row: int) -> Room.Type:
	if row == 0:
		return Room.Type.BATTLE
	if row == ROWS - 1:
		return Room.Type.BOSS
	if row == 3 and randi() % 2 == 0:
		return Room.Type.TREASURE

	var total := 0.0
	for weight in TYPE_WEIGHTS.values():
		total += weight
	var roll := randf() * total
	for type in TYPE_WEIGHTS.keys():
		roll -= TYPE_WEIGHTS[type]
		if roll <= 0.0:
			return type
	return Room.Type.BATTLE

static func _assign_battles(rooms: Array) -> void:
	for room in rooms:
		var room_typed: Room = room
		if room_typed.type not in [Room.Type.BATTLE, Room.Type.ELITE, Room.Type.BOSS]:
			continue
		var elite := room_typed.type in [Room.Type.ELITE, Room.Type.BOSS]
		room_typed.battle_stats = BattlePool.pick(room_typed.row + 1, elite)

## P34：房间不和它的父房间同类型（视频里是 _room_has_parent_of_type）
static func _avoid_type_chains(rooms: Array) -> void:
	var parents := {}
	for i in rooms.size():
		for j in rooms[i].next:
			if not parents.has(j):
				parents[j] = []
			parents[j].append(i)

	for i in rooms.size():
		var room: Room = rooms[i]
		if room.type != Room.Type.CAMPFIRE and room.type != Room.Type.SHOP:
			continue
		for parent_index in parents.get(i, []):
			if rooms[parent_index].type == room.type:
				room.type = Room.Type.BATTLE
				break