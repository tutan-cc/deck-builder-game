class_name StatusEffect
extends Effect

## 给目标挂状态。Bash 就是"造成伤害 + 施加易伤"。

@export var status := Stats.VULNERABLE
@export var stacks := 2


func execute(targets: Array, _source = null) -> void:
	for target in targets:
		if target and target.has_method("add_status"):
			target.add_status(status, stacks)
