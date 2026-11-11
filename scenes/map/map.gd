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

## 房间类型 → 12×12 图标。原来是一个汉字（战/精/事/商/营/宝/王），
## 汉字要读，图标可以直接扫。
const ROOM_ICONS := {
	Room.Type.BATTLE: preload("res://art/map/room_battle.png"),
	Room.Type.ELITE: preload("res://art/map/room_elite.png"),
	Room.Type.EVENT: preload("res://art/map/room_event.png"),
	Room.Type.SHOP: preload("res://art/map/room_shop.png"),
	Room.Type.CAMPFIRE: preload("res://art/map/room_campfire.png"),
	Room.Type.TREASURE: preload("res://art/map/room_treasure.png"),
	Room.Type.BOSS: preload("res://art/map/room_boss.png"),
}

@onready var scroll: ScrollContainer = $Scroll
@onready var content: Control = $Scroll/Content
@onready var rooms_root: Control = $Scroll/Content/Rooms
@onready var lines: Node2D = $Scroll/Content/Lines
@onready var info: Label = $Info
@onready var back_button: Button = $Back

var rooms: Array = []
var nodes: Array = []
## 每条房间的金色描边（可走时显示）
var frames: Array = []
## "你在这里"标记：一条金色小横杠，贴在当前位置房间的上沿
var marker: ColorRect


func _ready() -> void:
	if RunState.map_rooms.is_empty():
		RunState.new_map()
	rooms = RunState.map_rooms
	back_button.pressed.connect(func() -> void:
		Juice.fade_transition("res://scenes/run/run.tscn"))
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
	frames.clear()

	for i in rooms.size():
		var room: Room = rooms[i]
		var holder := Control.new()
		holder.position = _pos(room)
		holder.size = ROOM_SIZE
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.gui_input.connect(_on_room_input.bind(i))

		var bg := ColorRect.new()
		bg.size = ROOM_SIZE
		# 压暗类型色当底：图标要压在它上面，背景不能抢
		bg.color = room.color().darkened(0.55)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(bg)

		var icon := TextureRect.new()
		icon.texture = ROOM_ICONS.get(room.type)
		icon.position = Vector2(6, 2)
		icon.size = Vector2(12, 12)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)

		# 可走房间的金色描边。用 modulate 提亮不行——它是乘法，
		# 红色精英房提亮后还是红的，玩家分不清"能走"和"不能走"。
		var frame := Panel.new()
		frame.size = ROOM_SIZE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(1.0, 0.84, 0.38, 1.0)
		sb.set_border_width_all(1)
		frame.add_theme_stylebox_override("panel", sb)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.visible = false
		holder.add_child(frame)
		frames.append(frame)

		rooms_root.add_child(holder)
		nodes.append(holder)

		# P35：可去的房间悬停会亮一下（视频里用的是 AnimationPlayer，这里用 tween）
		holder.mouse_entered.connect(func() -> void:
			if RunState.available_rooms().has(i):
				holder.modulate = Color(1.6, 1.55, 1.3))
		holder.mouse_exited.connect(func() -> void:
			_refresh())

	# "你在这里"标记（金色横杠，压在房间上沿）
	marker = ColorRect.new()
	marker.size = Vector2(ROOM_SIZE.x, 2)
	marker.color = Color(1.0, 0.84, 0.38)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rooms_root.add_child(marker)

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
			holder.modulate = Color(1.18, 1.14, 1.0)
			if i < frames.size():
				frames[i].visible = true
		elif room.visited:
			holder.modulate = Color(0.55, 0.65, 0.55)      # 走过的
		else:
			holder.modulate = Color(0.55, 0.55, 0.6, 0.9)

	var room_now := RunState.current_room
	if marker:
		if room_now >= 0 and room_now < nodes.size():
			marker.visible = true
			marker.position = _pos(rooms[room_now]) + Vector2(0, -3)
		else:
			marker.visible = false

	if room_now >= 0 and room_now < rooms.size():
		# 提示要短：太长会撞到右下角"返回"按钮，也会被左边界切掉首字
		var tail := " → 点亮房间" if not available.is_empty() else " · 本层到头"
		info.text = "第 %d 层 · %d 金%s" % [rooms[room_now].row + 1, RunState.gold, tail]
	else:
		info.text = "选起点 · 点金框 · %d 金" % RunState.gold


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
	# 过场走 Juice.fade_transition：淡出 → 换场景 → 淡入。
	await Juice.fade_transition(RunState.scene_for(room.type))
