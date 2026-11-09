class_name EnemyAction
extends Resource

## 一个"敌人可以做的动作"。
##
## P16 帧里能看到视频的做法：每个动作是独立脚本（crab_attack_action.gd、
## crab_mega_block_action.gd…），都 extends EnemyAction，自己实现行为。
## 这里保留 type/value 的默认实现，但把 execute 变成可覆写的钩子——
## 想要"打两下""打人同时加护盾"这种特殊动作，写个子类就行，不用改 Enemy。

enum Type { ATTACK, BLOCK, BUFF }

@export var type: Type = Type.ATTACK
@export var value := 6
@export var weight := 1.0
@export var min_turn := 0      # 条件：第几回合之后才可能被选中


func label() -> String:
	match type:
		Type.ATTACK:
			return str(value)
		Type.BLOCK:
			return "B%d" % value
		_:
			return "▲"


## 默认行为：攻击扣血、格挡加盾。子类可以整个覆写。
## 伤害同样过状态：出手方力量/虚弱，挨打方易伤。
func execute(actor: Node, target: Node) -> void:
	match type:
		Type.ATTACK:
			if target == null:
				return
			var damage := float(value)
			if actor and actor.get("stats") is Stats:
				damage += float(actor.stats.get_status(Stats.STRENGTH))
				if actor.stats.get_status(Stats.WEAK) > 0:
					damage *= 0.75
			var out := maxi(0, int(round(damage)))
			if target.get("stats") is Stats and target.stats.get_status(Stats.VULNERABLE) > 0:
				out = int(round(out * 1.5))
			if target.has_method("take_damage"):
				target.take_damage(out)
		Type.BLOCK:
			if actor and actor.has_method("add_block"):
				actor.add_block(value)
		_:
			pass
