class_name Card
extends Resource

## 一张卡的**数据**，不含任何界面。卡面怎么画是 CardUI 的事，这里只管"是什么"。
## 这样同一张 "Strike" 可以在手牌、牌堆、商店、奖励界面复用同一份数据。

enum Type { ATTACK, SKILL, POWER }
enum Target { SELF, SINGLE_ENEMY, ALL_ENEMIES }
## P27：稀有度。只影响外观和奖励权重，不影响战斗结算。
enum Rarity { COMMON, UNCOMMON, RARE }

const RARITY_COLORS := {
	Rarity.COMMON: Color(0.62, 0.60, 0.56),
	Rarity.UNCOMMON: Color(0.45, 0.66, 0.92),
	Rarity.RARE: Color(0.95, 0.78, 0.35),
}

@export_group("属性")
@export var id: String = ""
@export var type: Type = Type.ATTACK
@export var target: Target = Target.SINGLE_ENEMY
@export var cost: int = 1
@export var rarity: Rarity = Rarity.COMMON

@export_group("表现")
@export var title: String = ""
@export var icon: Texture2D
@export_multiline var tooltip_text: String = ""

@export_group("效果")
@export var effects: Array[Effect] = []


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


## 把"打给谁"翻译成实际节点列表。传进来的是玩家瞄准时选中的目标（可能为空）。
func resolve_targets(selected: Array) -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return selected
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		_:
			return selected


func apply(selected: Array, source = null) -> void:
	var targets := resolve_targets(selected)
	for effect: Effect in effects:
		effect.execute(targets, source)

## 卡面上那一行短说明。
## 注意：256×144 的视口里 6px 的中文会糊成一团，所以这里用 ASCII 缩写，
## 中文解释放在悬停提示和"玩法"面板里。
func short_text() -> String:
	var parts: Array = []
	for effect: Effect in effects:
		if effect is DamageEffect:
			parts.append("%d伤" % effect.amount)
		elif effect is BlockEffect:
			parts.append("%d盾" % effect.amount)
		elif effect is StatusEffect:
			var label := "易" if effect.status == Stats.VULNERABLE else ("力" if effect.status == Stats.STRENGTH else "弱")
			parts.append("%s %d" % [label, effect.stacks])
	return "".join(parts)