class_name RewardPool

## P28/P29：奖励卡池。按稀有度抽，权重写在表里——
## "三选一大多数是普通卡、偶尔出稀有"这条规则，应该是一个数字，不是一串 if。

const RARITY_WEIGHTS := {
	Card.Rarity.COMMON: 60.0,
	Card.Rarity.UNCOMMON: 30.0,
	Card.Rarity.RARE: 10.0,
}


static func all_cards() -> Array:
	var cards: Array = []
	for factory in [
		CardLibrary.strike, CardLibrary.defend, CardLibrary.cleave,
		CardLibrary.bash, CardLibrary.iron_wave,
	]:
		cards.append(factory.call())
	return cards


## 抽 n 张不重复的卡。返回的是**新实例**，可以直接塞进卡组。
static func draw(count: int) -> Array:
	var pool := all_cards()
	var picked: Array = []
	var used_ids := {}

	# 先按稀有度加权挑，单调太久就退化成均匀抽，避免死循环
	var guard := 0
	while picked.size() < count and guard < 200:
		guard += 1
		var card: Card = _weighted_pick(pool)
		if card == null:
			break
		if used_ids.has(card.id):
			continue
		used_ids[card.id] = true
		picked.append(card)

	# 卡池比要的少时，允许重复补齐
	while picked.size() < count and not pool.is_empty():
		picked.append(pool[picked.size() % pool.size()])

	return picked


static func _weighted_pick(pool: Array) -> Card:
	var total := 0.0
	for card in pool:
		total += RARITY_WEIGHTS.get(card.rarity, 1.0)
	if total <= 0.0:
		return null
	var roll := randf() * total
	for card in pool:
		roll -= RARITY_WEIGHTS.get(card.rarity, 1.0)
		if roll <= 0.0:
			return card
	return pool[pool.size() - 1]
