class_name BlockEffect
extends Effect

## 加格挡。格挡先扣伤害，扣不完的下一回合清空（见 Stats.clear_block）。

@export var amount := 5


func execute(targets: Array, _source = null) -> void:
	for target in targets:
		if target == null:
			continue
		if target.has_method("add_block"):
			target.add_block(amount)
