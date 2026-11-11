extends Node

## P23：跨场景中枢。主菜单选角色 → 写进这里；Run/战斗读这里。
## 没有它，场景一切换数据就全丢了。

var character: Character
var deck: Array[Card] = []
var relics: Array[Relic] = []
var depth := 1
## P28：金币。战斗奖励会给，将来商店要花
var gold := 0
## P28：Run 统计。目前只记胜场，后面商店/遗物都会读
var battles_won := 0

## P31：地图。房间列表 + 当前所在（-1 = 还没进图）
var map_rooms: Array = []
var current_room := -1
## P39：血量要跨战斗保留，-1 表示"满血开始"
var current_health := -1
## P37：当前这场遭遇战（BattleStats）
var current_encounter: BattleStats


func start_run(chosen: Character) -> void:
	character = chosen
	depth = 1
	gold = 0
	battles_won = 0
	current_health = -1
	new_map()
	deck.clear()
	for card in chosen.starting_deck:
		deck.append(card)
	relics.clear()
	add_relic(default_relic())


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


func reset() -> void:
	start_run(Character.warrior())


func add_card(card: Card) -> void:
	if card:
		deck.append(card)


func add_relic(relic: Relic) -> void:
	if relic:
		relics.append(relic)


func apply_to(stats: CharacterStats) -> void:
	if character:
		stats.max_health = character.max_health + bonus_max_health()
		stats.max_energy = character.max_energy
		stats.energy = character.max_energy
	for relic in relics:
		relic.apply_to(stats)
	# P39：血量跨战斗保留；-1 或超上限时按满血
	stats.health = stats.max_health if current_health < 0 else mini(current_health, stats.max_health)


# ---------- P31 地图 ----------

func new_map() -> void:
	map_rooms = MapGenerator.generate()
	current_room = -1


## 从当前位置能去的房间下标；还没进图时，第一行全部可选
func available_rooms() -> Array:
	var out: Array = []
	if map_rooms.is_empty():
		return out
	if current_room < 0:
		for i in map_rooms.size():
			if map_rooms[i].row == 0:
				out.append(i)
		return out
	if current_room >= map_rooms.size():
		return out
	var here: Room = map_rooms[current_room]
	out = here.next.duplicate()
	# 兜底：万一这间房的 next 空了（生成或删线出问题），玩家会被硬卡在地图上。
	# 这里直接从下一行捞房间接上，宁可多一条没画出来的边，也不能走不动。
	if out.is_empty() and here.row < MapGenerator.ROWS - 1:
		for i in map_rooms.size():
			if (map_rooms[i] as Room).row == here.row + 1:
				out.append(i)
		push_warning("地图死胡同：房间 %d（第 %d 层）没有出路，已自动接下一行" % [current_room, here.row + 1])
	return out


func scene_for(type: int) -> String:
	match type:
		Room.Type.CAMPFIRE:
			return "res://scenes/campfire/campfire.tscn"
		Room.Type.BATTLE, Room.Type.ELITE, Room.Type.BOSS:
			return "res://scenes/battle/battle.tscn"
		Room.Type.SHOP, Room.Type.EVENT, Room.Type.TREASURE:
			return "res://scenes/rooms/room_event.tscn"
		_:
			return "res://scenes/map/map.tscn"


## 当前房间的类型（不在图上时按普通战斗算）
func current_room_type() -> int:
	if current_room >= 0 and current_room < map_rooms.size():
		return (map_rooms[current_room] as Room).type
	return Room.Type.BATTLE


## 玩家唯一随层数成长的东西。原来血量上限写死 35，敌人却按 1.6 倍变强，
## 深度 5 之后数学上就打不赢了。
func bonus_max_health() -> int:
	return maxi(0, depth - 1) * 4


func heal(amount: int) -> int:
	if character == null:
		return 0
	var max_hp := character.max_health + bonus_max_health()
	var now := max_hp if current_health < 0 else current_health
	var healed := mini(max_hp - now, amount)
	current_health = now + healed
	return healed


func relic_titles() -> Array:
	var out: Array = []
	for relic in relics:
		out.append(relic.title)
	return out


func character_title() -> String:
	return character.title if character else "无名"


func default_relic() -> Relic:
	return RelicLibrary.broken_anchor()


## P37：玩家回合开始时触发所有遗物（每回合格挡 / 每回合能量）
func turn_start_hooks(player: Node) -> void:
	for relic in relics:
		relic.on_turn_start(player)


## P37：受伤减伤（荆棘环这类）
func damage_reduction() -> int:
	var total := 0
	for relic in relics:
		if relic.trigger == Relic.Trigger.DAMAGE_REDUCTION:
			total += relic.amount
	return total
