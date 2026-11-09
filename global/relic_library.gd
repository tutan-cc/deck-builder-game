class_name RelicLibrary

## 遗物表。跟 CardLibrary 一个思路：内容集中，靠数据而不是靠分支。

static func broken_anchor() -> Relic:
	var relic := Relic.new()
	relic.id = "broken_anchor"
	relic.title = "断裂的锚"
	relic.description = "能量上限 +1。"
	relic.trigger = Relic.Trigger.PASSIVE
	relic.bonus_energy = 1
	relic.icon = load("res://art/tile_0074.png")
	return relic


static func turtle_shell() -> Relic:
	var relic := Relic.new()
	relic.id = "turtle_shell"
	relic.title = "龟壳"
	relic.description = "每回合开始获得 3 点格挡。"
	relic.trigger = Relic.Trigger.TURN_START_BLOCK
	relic.amount = 3
	relic.icon = load("res://art/tile_0084.png")
	return relic


static func whetstone() -> Relic:
	var relic := Relic.new()
	relic.id = "whetstone"
	relic.title = "磨刀石"
	relic.description = "生命上限 +8。"
	relic.trigger = Relic.Trigger.PASSIVE
	relic.bonus_max_health = 8
	relic.icon = load("res://art/tile_0124.png")
	return relic


static func thorn_ring() -> Relic:
	var relic := Relic.new()
	relic.id = "thorn_ring"
	relic.title = "荆棘环"
	relic.description = "受到的伤害 -2。"
	relic.trigger = Relic.Trigger.DAMAGE_REDUCTION
	relic.amount = 2
	relic.icon = load("res://art/tile_0108.png")
	return relic


## 精英/Boss 掉落池（不和初始遗物重复）
static func reward_pool() -> Array:
	return [turtle_shell(), whetstone(), thorn_ring()]


static func random_reward() -> Relic:
	var pool := reward_pool()
	return pool[randi() % pool.size()]
