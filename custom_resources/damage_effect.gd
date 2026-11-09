class_name DamageEffect
extends Effect

## 造成伤害。状态在这里生效：
##   出手方：力量 +N 点、虚弱 ×0.75
##   挨打方：易伤 ×1.5
##
## 传进来的可能是 Stats，也可能是 Player/Enemy 节点，统一用 _stats_of 取。

@export var amount := 6


func execute(targets: Array, source = null) -> void:
	var source_stats := _stats_of(source)
	var base := float(amount)
	if source_stats:
		base += float(source_stats.get_status(Stats.STRENGTH))
		if source_stats.get_status(Stats.WEAK) > 0:
			base *= 0.75
	var damage := maxi(0, int(round(base)))

	for target in targets:
		if target == null:
			continue
		var out := damage
		var target_stats := _stats_of(target)
		if target_stats and target_stats.get_status(Stats.VULNERABLE) > 0:
			out = int(round(out * 1.5))
		if target.has_method("take_damage"):
			target.take_damage(out)


func _stats_of(thing) -> Stats:
	if thing == null:
		return null
	if thing is Stats:
		return thing
	var candidate = thing.get("stats")
	return candidate if candidate is Stats else null
