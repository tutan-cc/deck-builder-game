class_name BattleStats
extends Resource

## P37/P38：一场遭遇战是**数据**，不是一个写死的场景。
## 视频里是 res://battles/tier_1_bat_crab.tres 这种，一个遭遇一份资源。
##
## 我用"敌人数量 + 倍率"代替"敌人场景数组"：敌人种类目前只有一种，
## 差别在数量和强度上——真要多兵种，把这字段换成 Array[PackedScene] 即可。

@export var id: String = ""
@export var battle_tier := 1
@export var weight := 1.0
@export var gold_reward_min := 10
@export var gold_reward_max := 18
@export var enemy_count := 2
## P38：敌人种类（"bat" / "crab"），按顺序循环使用
@export var enemy_kinds: Array[String] = []
@export var hp_multiplier := 1.0
@export var damage_multiplier := 1.0


func roll_gold() -> int:
	return randi_range(gold_reward_min, gold_reward_max)
