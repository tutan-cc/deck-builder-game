class_name CardLibrary

## P21/P22：卡牌的"工厂"。原来卡是在 Battle 里 new 出来的，
## 一旦角色选择、奖励、商店都要用同一批卡，就必须集中到一处。

static func strike() -> Card:
	var card := Card.new()
	card.id = "strike"
	card.title = "打击"
	card.cost = 1
	card.type = Card.Type.ATTACK
	card.target = Card.Target.SINGLE_ENEMY
	var effect := DamageEffect.new()
	effect.amount = 6
	card.effects.append(effect)
	card.icon = load("res://art/cards/icons/icon_strike.png")
	card.tooltip_text = "Deal 6 damage."
	card.rarity = Card.Rarity.COMMON
	return card


static func defend() -> Card:
	var card := Card.new()
	card.id = "defend"
	card.title = "防御"
	card.cost = 1
	card.type = Card.Type.SKILL
	card.target = Card.Target.SELF
	var effect := BlockEffect.new()
	effect.amount = 5
	card.effects.append(effect)
	card.icon = load("res://art/cards/icons/icon_defend.png")
	card.tooltip_text = "Gain 5 block."
	return card


static func cleave() -> Card:
	var card := strike()
	card.id = "cleave"
	card.title = "横扫"
	card.target = Card.Target.ALL_ENEMIES
	var effect: DamageEffect = card.effects[0]
	effect.amount = 4
	card.rarity = Card.Rarity.UNCOMMON
	card.tooltip_text = "Deal 4 damage to ALL enemies."
	card.icon = load("res://art/cards/icons/icon_cleave.png")
	return card


static func bash() -> Card:
	var card := strike()
	card.id = "bash"
	card.title = "重击"
	card.cost = 2
	var effect: DamageEffect = card.effects[0]
	effect.amount = 8
	var vulnerable := StatusEffect.new()
	vulnerable.status = Stats.VULNERABLE
	vulnerable.stacks = 2
	card.effects.append(vulnerable)
	card.rarity = Card.Rarity.UNCOMMON
	card.tooltip_text = "Deal 8 damage. Apply 2 Vulnerable."
	card.icon = load("res://art/cards/icons/icon_bash.png")
	return card


## 两个效果串在一张卡上（伤害 + 格挡），验证 effects 数组是可组合的
static func iron_wave() -> Card:
	var card := strike()
	card.id = "iron_wave"
	card.title = "铁壁"
	card.type = Card.Type.ATTACK
	var damage: DamageEffect = card.effects[0]
	damage.amount = 5
	var block := BlockEffect.new()
	block.amount = 5
	card.effects.append(block)
	card.rarity = Card.Rarity.RARE
	card.tooltip_text = "Deal 5 damage. Gain 5 block."
	card.icon = load("res://art/cards/icons/icon_iron_wave.png")
	return card


## 奖励池（P25 之后的三选一从这里抽）
static func pool() -> Array:
	return [strike(), defend(), cleave(), bash(), iron_wave()]


## P39：营地升级。数值 ×1.5，名字加个 "+"，其它（图标、类型、目标）照旧。
static func upgrade(card: Card) -> Card:
	var upgraded: Card = card.duplicate(true)
	upgraded.title = card.title + "+"
	for effect in upgraded.effects:
		if effect is DamageEffect:
			effect.amount = maxi(1, int(round(effect.amount * 1.5)))
		elif effect is BlockEffect:
			effect.amount = maxi(1, int(round(effect.amount * 1.5)))
	return upgraded
