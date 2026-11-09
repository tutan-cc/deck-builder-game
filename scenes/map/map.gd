extends Control

## P35/P36：地图可视化。房间是「色块 + 文字」，连线是 Line2D。
## 只有"从当前位置能到的房间"可以点——这就是解锁逻辑。
##
## 为什么不用 Button：Button 的最小尺寸由主题字体决定，7 行 × 31px 会叠在一起，
## 自己摆 Control 才能精确控制大小。

const ROOM_SIZE := Vector2(24, 16)
const SPACING_X := 32.0
const SPACING_Y := 18.0
const ORIGIN := Vector2(20, 16)

@onready var scroll: ScrollContainer = $Scroll
@onready var content: Control = $Scroll/Content
@onready var rooms_root: Control = $Scroll/Content/Rooms
@onready var lines: Node2D = $Scroll/Content/Lines
@onready var info: Label = $Info
@onready var back_button: Button = $Back

var rooms: Array = []
var nodes: Array = []


func _ready() -> void:
	if RunState.map_rooms.is_empty():
		RunState.new_map()
	rooms = RunState.map_rooms
	back_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run/run.tscn"))
	content.custom_minimum_size = Vector2(256, MapGenerator.ROWS * SPACING_Y + ORIGIN.y + 26)
	_build()
	_refresh()
	_scroll_to_current.call_deferred()


func _scroll_to_current() -> void:
	if RunState.current_room < 0 or RunState.current_room >= rooms.size():
		return
	var y := _pos(rooms[RunState.current_room]).y
	scroll.scroll_vertical = int(maxf(0.0, y - 56.0))


func _pos(room: Room) -> Vector2:
	return ORIGIN + Vector2(SPACING_X * room.col, SPACING_Y * room.row)


func _build() -> void:
	for child in rooms_root.get_children():
		child.queue_free()
	for child in lines.get_children():
		child.queue_free()
	nodes.clear()

	for i in rooms.size():
		var room: Room = rooms[i]
		var holder := Control.new()
		holder.position = _pos(room)
		holder.size = ROOM_SIZE
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.gui_input.connect(_on_room_input.bind(i))

		var bg := ColorRect.new()
		bg.size = ROOM_SIZE
		bg.color = room.color()
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(bg)

		var label := Label.new()
		label.text = room.label()
		label.size = ROOM_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(label)

		rooms_root.add_child(holder)
		nodes.append(holder)

		# P35：可去的房间悬停会亮一下（视频里用的是 AnimationPlayer，这里用 tween）
		holder.mouse_entered.connect(func() -> void:
			if RunState.available_rooms().has(i):
				holder.modulate = Color(1.6, 1.55, 1.3))
		holder.mouse_exited.connect(func() -> void:
			_refresh())

	for i in rooms.size():
		for j in rooms[i].next:
			var line := Line2D.new()
			line.add_point(_pos(rooms[i]) + ROOM_SIZE * 0.5)
			line.add_point(_pos(rooms[j]) + ROOM_SIZE * 0.5)
			line.width = 1.0
			line.default_color = Color(0.62, 0.55, 0.40, 0.75)
			lines.add_child(line)


func _refresh() -> void:
	var available := RunState.available_rooms()
	for i in nodes.size():
		var holder: Control = nodes[i]
		var room: Room = rooms[i]
		if available.has(i):
			holder.modulate = Color(1.25, 1.2, 1.05)      # 亮一点 = 能去
		elif room.visited:
			holder.modulate = Color(0.55, 0.65, 0.55)      # 走过的
		else:
			holder.modulate = Color(0.62, 0.62, 0.68, 0.9)

	var room_now := RunState.current_room
	if room_now >= 0 and room_now < rooms.size():
		info.text = "%s · 第 %d 层 · 金币 %d" % [rooms[room_now].label(), rooms[room_now].row + 1, RunState.gold]
	else:
		info.text = "选择起点 · 金币 %d" % RunState.gold


func _on_room_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not RunState.available_rooms().has(index):
		return
	await _enter(index)


func _enter(index: int) -> void:
	var room: Room = rooms[index]
	RunState.current_room = index
	room.visited = true
	RunState.depth = room.row + 1

	# 宝箱 / 事件 / 商店 现在有独立场景（scenes/rooms/room_event.tscn）
	get_tree().change_scene_to_file(RunState.scene_for(room.type))
