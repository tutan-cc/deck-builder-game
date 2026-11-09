class_name CharacterStats
extends Stats

## 玩家用的数值：在生命/格挡之外多一个能量。

@export var max_energy := 3

var energy: int: set = set_energy


func _init() -> void:
	super()
	energy = max_energy


func set_energy(value: int) -> void:
	energy = clampi(value, 0, max_energy)
	stats_changed.emit()


func reset_energy() -> void:
	energy = max_energy
