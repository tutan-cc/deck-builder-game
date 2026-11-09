class_name BattlePool

## P38：战斗池。按地图层数决定 tier，再按权重抽一场。
## 越深的层数允许出现 tier 更高的遭遇（敌人更多更硬），但低 tier 仍会抽到——
## 这样回头走过的地图不会突然全是精英。

static func encounters() -> Array:
	var list: Array = []

	var single := BattleStats.new()
	single.id = "tier1_single"
	single.battle_tier = 1
	single.weight = 3.0
	single.enemy_count = 1
	single.enemy_kinds = ["bat"]
	single.hp_multiplier = 0.8
	single.damage_multiplier = 0.8
	single.gold_reward_min = 8
	single.gold_reward_max = 14
	list.append(single)

	var pair := BattleStats.new()
	pair.id = "tier1_pair"
	pair.battle_tier = 1
	pair.weight = 3.0
	pair.enemy_count = 2
	pair.enemy_kinds = ["bat", "crab"]
	pair.gold_reward_min = 12
	pair.gold_reward_max = 20
	list.append(pair)

	var tough_pair := BattleStats.new()
	tough_pair.id = "tier2_pair"
	tough_pair.battle_tier = 2
	tough_pair.weight = 2.0
	tough_pair.enemy_count = 2
	tough_pair.enemy_kinds = ["crab", "crab"]
	tough_pair.hp_multiplier = 1.4
	tough_pair.damage_multiplier = 1.3
	tough_pair.gold_reward_min = 18
	tough_pair.gold_reward_max = 28
	list.append(tough_pair)

	var trio := BattleStats.new()
	trio.id = "tier3_trio"
	trio.battle_tier = 3
	trio.weight = 1.0
	trio.enemy_count = 3
	trio.enemy_kinds = ["bat", "crab", "bat"]
	trio.hp_multiplier = 1.2
	trio.damage_multiplier = 1.1
	trio.gold_reward_min = 24
	trio.gold_reward_max = 36
	list.append(trio)

	return list


## tier 上限由地图层数决定：第 1 层只能遇到 tier 1，第 5 层以后才会出现 tier 3
static func tier_for_depth(depth: int) -> int:
	if depth <= 2:
		return 1
	if depth <= 4:
		return 2
	return 3


static func pick(depth: int, elite_or_boss := false) -> BattleStats:
	var cap := tier_for_depth(depth)
	var pool: Array = []
	var total := 0.0
	for encounter in encounters():
		if encounter.battle_tier > cap:
			continue
		# 精英/Boss 偏向高 tier：低 tier 的权重砍掉一半
		var weight: float = encounter.weight
		if elite_or_boss and encounter.battle_tier < cap:
			weight *= 0.5
		pool.append([encounter, weight])
		total += weight

	if pool.is_empty():
		return encounters()[0]

	var roll := randf() * total
	for entry in pool:
		roll -= entry[1]
		if roll <= 0.0:
			return entry[0]
	return pool[pool.size() - 1][0]
