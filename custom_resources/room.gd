class_name Room
extends Resource

## P31–P34：地图上的一个房间。只描述"我是什么、我在哪、我通向谁"，
## 具体场景（战斗/营地/商店）由进房间的时候决定。

enum Type { BATTLE, ELITE, EVENT, SHOP, CAMPFIRE, TREASURE, BOSS }

@export var type: Type = Type.BATTLE
@export var row := 0
@export var col := 0
@export var next: Array[int] = []      # 下一行能去的房间下标
@export var visited := false
## P38：这间房打什么由房间自己带（视频里是 boss_room.battle_stats = ...）
@export var battle_stats: BattleStats


func label() -> String:
	match type:
		Type.BATTLE: return "战"
		Type.ELITE: return "精"
		Type.EVENT: return "事"
		Type.SHOP: return "商"
		Type.CAMPFIRE: return "营"
		Type.TREASURE: return "宝"
		Type.BOSS: return "王"
		_: return "?"


func color() -> Color:
	match type:
		Type.BATTLE: return Color(0.62, 0.36, 0.34)
		Type.ELITE: return Color(0.72, 0.28, 0.42)
		Type.EVENT: return Color(0.38, 0.52, 0.62)
		Type.SHOP: return Color(0.55, 0.50, 0.30)
		Type.CAMPFIRE: return Color(0.75, 0.50, 0.22)
		Type.TREASURE: return Color(0.45, 0.62, 0.40)
		Type.BOSS: return Color(0.66, 0.22, 0.25)
		_: return Color(0.4, 0.4, 0.4)
